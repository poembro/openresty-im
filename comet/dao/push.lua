require "resty.core" 
local cjson = require "cjson" 
local string_format = string.format 
local ngx_md5 = ngx.md5
local type = type
local table = table
local pairs = pairs
local ipairs = ipairs
local string_gsub = string.gsub
local keyMidServer = function (mid) return string_format("mid_%d", mid) end
local keyKeyServer = function (key)  return string_format("key_%s", key) end
local keyServerOnline = function (key) return string_format("ol_%s", key) end
local keyRoomId = function (typ, room_id)  return string_format("%s://%d", typ, room_id) end
local createKey = function(mid, room_id) return ngx_md5(tostring(mid) .. "-web-" .. tostring(room_id)) end

local BaseAPI = require("comet.dao.base_handler")
local _M = BaseAPI:extend()

local dump = function (v)
    local __dump
	if not __dump then
		__dump = function (v, t, p)    
			local k = p or "";

			if type(v) ~= "table" then
				table.insert(t, k .. " : " .. tostring(v));
			else
				for key, value in pairs(v) do
					__dump(value, t, k .. "[" .. key .. "]");
				end
			end
		end
	end

	local t = {'======== Lib:Dump Content ========'};
	__dump(v, t);
	print(table.concat(t, "\n"));
end

-- 创建用户uid
function _M:createMid()    
    local key = ngx.today()
    local ok, err = self:conn():incrby(key, 1)
    if err then
        return ngx.now() *1000
    end
    if ok == 1 then
        self:conn():expire(key, 86401)
    end
    local newstr = string_gsub(key, "-", "")
    local id =  newstr .. ok
    return id
end

function _M:acceptRoom(shop_id, mid)
    local acceptRoom = ""
    if tonumber(mid) > tonumber(shop_id) then 
        acceptRoom = shop_id .. mid 
    else 
        acceptRoom = mid .. shop_id 
    end
    return acceptRoom, keyRoomId("live", acceptRoom)
end

-- 生成加密key
function _M:createKey(real_room_id, mid)
    local key = createKey(mid, real_room_id)
    --ngx.log(ngx.DEBUG, "---前-->>", mid .. "-web-" .. real_room_id) 
    --ngx.log(ngx.DEBUG, "---前-->>", key)
    return key
end

-- 校验加密key
function _M:verify(userBody) 
    if not userBody then
        return false, {}
    end
    local arr = cjson.decode(userBody)
    local mid = tostring(arr.mid)
    local room_id = arr.room_id
    local shop_id = arr.shop_id
    local srv = ngx.var.server_addr

    local key = createKey(mid, room_id) 
    --ngx.log(ngx.DEBUG, "--后-->>", mid .. "-web-" .. room_id) 
    --ngx.log(ngx.DEBUG, "--后-->>", key,  "-->>", arr.key)
    if key == arr.key then 
        -- 验证通过后写入 redis hset
        self:addMapping(mid, key, srv, userBody) 
        -- 作为商户在线列表 zadd
        self:addUserList(shop_id, mid) 
        -- 系统运营
        self:addSysTotal(shop_id)
        return true, arr
    end 

    return false, arr
end


-- 一个用户多个设备的情况下 
function _M:addMapping(mid, key, srv, user)
    local midkey = keyMidServer(mid)
    local ok, err 
    ok, err = self:conn():hset(midkey, key, user) 
    ok, err = self:conn():expire(midkey, 86400*7)
    
    local keykey = keyKeyServer(key) 
    ok, err = self:conn():set(keykey, srv, 'EX', 60) 
    return ok
end

-- 心跳包维持在线
function _M:expireMapping(mid, key)
    local keykey = keyKeyServer(key)  
    self:conn():expire(keykey, 60)
end

-- 通过mid拿到所有key
function _M:KeysByMids(mid)
    local midkey = keyMidServer(mid) 
    return self:conn():hgetall(midkey) 
end

-- 推送
function _M:publish(data)
    local topic = "goim-push-topic"   
    local msg = cjson.encode(data) 
    
    local ok, err 
    ok, err = self:conn():publish(topic, msg)
    if err then
        ngx.log(ngx.DEBUG, "--hset-->",ok or "", "  --- ", err or "")
    end
    -- 写入聊天记录
    self:addMsgList(data.id, data.room_id, msg)
    -- 写入临时队列 以方便监听有变化的用户
    self:conn():lpush("msg_notic_" .. data.shop_id, data.mid)
    return ok
end

-- 订阅
function _M:subscribe()   
    local topic = "goim-push-topic"
    return self:conn():subscribe(topic)  
end

-- 分发消息 同一个房间消息才下发
function _M:dispatch(user, rawdata)
    if not user then
        return false
    end
    
    if user.accepts and type(user.accepts) ~= "table" then
        user.accepts = cjson.decode(user.accepts)
        if not user.accepts then return false end
    end
    
    local data = cjson.decode(rawdata) -- 性能瓶颈点
    if not data then return false  end
    
    local room_id
    for _,val in pairs(user.accepts) do
        room_id = keyRoomId("live", val) 
        if data.room_id == room_id then 
            return rawdata
        end
    end
    return false 
end


-- 添加到商户下级列表
function _M:addUserList(shop_id, mid)
    return self:conn():zadd("userlist:" .. shop_id, ngx.time(), mid)
end

-- 查询商户下的用户列表
function _M:findUserList(shop_id)
    local arr = {}
    local res = self:conn():zrevrange("userlist:" .. shop_id, 0, 50)
    if not res then 
        return arr, false  
    end
    local user, online, seq, num, last
    for _, mid in ipairs(res) do
        if tonumber(mid) ~= tonumber(shop_id) then
            -- 用mid 去查找对应用户信息、在线状态
            user, online = self:toUserHandler(shop_id, mid)
            if user and user ~= "" then
                -- 用mid 去查找对应用户的已/未数、最后一条聊天记录
                seq, num, last = self:toHistoryMsgHandler(shop_id, mid)
                table.insert(arr, {user = user, online = online, seq = seq, num = num, last = last})
            end
        end
    end
    return arr, true
end

function _M:findUserStatus(shop_id)
    local arr = {}
    local mid = self:conn():rpop("msg_notic_" .. shop_id)
    if mid and mid ~= "" then
        local user, online, seq, num, last
        -- 用mid 去查找对应用户信息、在线状态
        user, online = self:toUserHandler(shop_id, mid)
        if user and user ~= "" then
            -- 用mid 去查找对应用户的已/未数、最后一条聊天记录
            seq, num, last = self:toHistoryMsgHandler(shop_id, mid)
            table.insert(arr, {user = user, online = online, seq = seq, num = num, last = last})
        end 
    end
    return arr, true
end

function _M:toUserHandler(shop_id, mid)
    local _, keyRoomId = self:acceptRoom(shop_id, mid)
    local key = createKey(mid, keyRoomId)
    local midkey = keyMidServer(mid)
    local user = self:conn():hget(midkey, key) 
    if not user then 
        return "", false
    end
    local keykey = keyKeyServer(key)  
    local online = self:conn():exists(keykey)
    return user, online
end

function _M:toHistoryMsgHandler(shop_id, mid)
    local last = ""
    local num = 0
    local msglist = {}
    local _, keyRoomId = self:acceptRoom(shop_id, mid) 
    local seq = self:findSeq(shop_id, keyRoomId) -- 拿商家的key去换偏移 以及 未读条数
    num = self:countMsgList(keyRoomId, seq, "+inf") -- 拿到偏移去统计未读
    num = num - 1
    if num <= 0 then
        num = 0
    end
    msglist = self:findMsgList(keyRoomId, 0, 0)
    if #msglist > 0 then
        last = msglist[1]
    end
    return seq, num, last
end


-- 添加已读偏移
function _M:addSeq(mid, room_id, seq)  
    if mid and seq and tonumber(seq) > 0 then 
        self:conn():hset("mid_seq:" .. mid, room_id, seq)
    end
end
-- 查询已读偏移
function _M:findSeq(mid, room_id)
    if not mid or not room_id then
        return 0
    end
    local res, err = self:conn():hget("mid_seq:" .. mid, room_id)
    if not res then
        return 0
    end
    return res
end


-- 添加聊天记录 
function _M:addMsgList(id, room_id, msg)
    return self:conn():zadd("msglist:" .. room_id, id, msg)
end
-- 查询聊天记录 
function _M:findMsgList(room_id, min, max)
    -- TODO 可以先zcount 一下 如果太大则下标的方式取
    local res = self:conn():zrevrange("msglist:" .. room_id, min, max)
    local arr = {}
    if not res then
         return arr
    end
    for _, value in ipairs(res) do
        table.insert(arr, value)
    end
    return arr
end
-- 偏移范围统计
function _M:countMsgList(room_id, min, max)
    local count = self:conn():zcount("msglist:" .. room_id, tostring(min), max)
    if not count then
        return 0
    end
    return tonumber(count)
end


-- 运营统计 (如删除老旧的聊天记录/商户下的聊天列表信息)
function _M:addSysTotal(shop_id)
    return self:conn():sadd("shoplist:", shop_id)
end

-- 删除老旧的记录 TODO
function _M:delSysTotal()
    local arr = {}
    local res = self:conn():smembers("shoplist:")
    if not res then 
        return arr, false  
    end
 
    for _, shop_id in ipairs(res) do 
        self:toDelHandler(shop_id) 
    end
    return arr, true  
end

function _M:toDelHandler(shop_id)
    local arr = {}
    local res = self:conn():zrange("userlist:" .. shop_id, 0, 50, "WITHSCORES")
    if not res then 
        return arr, false  
    end
    
    local now = ngx.time()
    local dateline, mid
    for key, value in ipairs(res) do
        if key % 2 == 1 and value and value ~= "" then
            mid = value
        end

        if key % 2 == 0 and value and value ~= "" then
            dateline = value 
            -- 因为遍历顺序是先有mid  再有时间
            if mid and now - tonumber(dateline) > 86400 * 7 then
                -- 删除mid用户信息
                local midkey = keyMidServer(mid)
                self:conn():del(midkey)  

                -- 删除商户与mid之间的聊天记录   TODO:删除部分聊天记录
                local _, keyRoomId = self:acceptRoom(shop_id, mid)
                self:conn():del("msglist:" .. keyRoomId) 
 
                -- 删除偏移
                local count = self:conn():hlen("mid_seq:".. mid)
                if count == 1 then
                    self:conn():del("mid_seq:" .. mid) 
                end
 
                -- 从商户列表中移除
                self:conn():zrem("userlist:" .. shop_id, mid)
            end
        end
    end
end

return _M
