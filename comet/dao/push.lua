 
require "resty.core" 
local cjson = require "cjson" 
local string_format = string.format 
local ngx_md5 = ngx.md5
local url = require("config").url
local _prefixMidServer = "mid_%d" 
local _prefixKeyServer = "key_%s" 
local _prefixServerOnline = "ol_%s" 
local keyMidServer = function (mid) return string_format(_prefixMidServer, mid) end
local keyKeyServer = function (key)  return string_format(_prefixKeyServer, key) end
local keyServerOnline = function (key) return string_format(_prefixServerOnline, key) end
 
local BaseAPI = require("comet.dao.base_handler")
local _M = BaseAPI:extend()

local _prefixRoomId = "%s://%d"
local keyRoomId = function (typ, room_id)  return string_format(_prefixRoomId, typ, room_id) end

local buildkey = function(mid, room_id)
    return ngx_md5(mid .. "-web-" .. room_id)
end

function _M:config(mid, room_id, accepts, name) 
    local room_id = keyRoomId("live", room_id)
    local key = buildkey(mid, room_id)

    -- ngx.log(ngx.ERR, "=======9======>>", mid .. "-web-" .. room_id)
    local data = {
        mid = mid,
        platform = 'web',
        room_id = room_id,
        accepts = "[1000,1001,1002]",
        key = key,
        room_name = name,
        url = url
    }
    return data
end

function _M:verify(data) 
    local arr = cjson.decode(data)
    local mid = tostring(arr.mid)
    local room_id = arr.room_id
    
    local key = buildkey(mid, room_id) 
    --ngx.log(ngx.ERR, "==>>", mid .. "-web-" .. room_id) 
    --ngx.log(ngx.ERR, "==>>", key,  "==>>", arr.key)
    if key == arr.key then 
        return true, arr
    end
    
    return false, arr
end 

function _M:publish(data)
    local topic = "goim-push-topic"   
    local msg = cjson.encode(data) 

    local ok, err 
    ok, err = self:connect():publish(topic, msg)
    if err then
        ngx.log(ngx.ERR, "--hset-->",ok or "", "  --- ", err or "")
    end
    return ok
end
 
function _M:subscribe()   
    local topic = "goim-push-topic"
    return self:connect():subscribe(topic)  
end 

--同一个房间消息才下发
function _M:dispatch(user, rawdata)
    if not user then
        return false
    end 

    local data = cjson.decode(rawdata)
      
    if data.room_id ~= user.room_id then
        return false
    end

    return rawdata
end


-- 一个用户多个设备的情况下 
function _M:addMapping(mid, key, server)
    local ttl = 60 
    local midkey = keyMidServer(mid)
    
    local ok, err 
    ok, err = self:connect():hset(midkey, key, server)
    if err then
        ngx.log(ngx.ERR, "--hset-->",ok or "", "  --- ", err or "")
    end

    ok, err = self:connect():expire(midkey, ttl)

    local keykey = keyKeyServer(key) 
    ok, err = self:connect():set(keykey, server, 'EX', ttl)
    if err then
        ngx.log(ngx.ERR, "--hset-->", ok or "", "  --- ", err or "")
    end 
    return ok
end

-- 心跳包维持在线
function _M:expireMapping(mid, key)
    local ttl = 60
    local midkey = keyMidServer(mid)
    local keykey = keyKeyServer(key)  
    self:connect():expire(midkey, ttl) 
    self:connect():expire(keykey, ttl)
end

-- 删除在线
function _M:delMapping(mid, key) 
    local midkey = keyMidServer(mid)
    local keykey = keyKeyServer(key)  
    self:connect():hdel(midkey, key)
    self:connect():del(keykey, ttl)
end 

--通过uid拿到所有设备id
function _M:KeysByMids(mid)
    local midkey = keyMidServer(mid) 
    local res = self:connect():hgetall(midkey)
    return res
end

return _M