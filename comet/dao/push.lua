 
 require "resty.core" 
 local rds = require "libs.iredis"
 local config = require("config")
 
 local string_format = string.format 
 local _prefixMidServer = "mid_%d" 
 local _prefixKeyServer = "key_%s" 
 local _prefixServerOnline = "ol_%s" 
 local keyMidServer = function (mid) return string_format(_prefixMidServer, mid) end
 local keyKeyServer = function (key)  return string_format(_prefixKeyServer, key) end
 local keyServerOnline = function (key) return string_format(_prefixServerOnline, key) end
 
  
 local ok, new_tab = pcall(require, "table.new")
 if not ok or type(new_tab) ~= "function" then
     new_tab = function (narr, nrec) return {} end
 end
 
 
 local _M = new_tab(0, 12)
 _M._VERSION = '0.01'
  
local instanse = nil 

function _M:connect() 
    if not instanse then
        local conf = config.redis 
        ngx.log(ngx.ERR, "--> new redis ")
        instanse = rds:new(conf) 
    end
    
    return instanse
end

-- 一个用户多个设备的情况下 
function _M:addMapping(mid, key, server)
    local ttl = 60 
    local midkey = keyMidServer(mid)
    
    local ok, err 
    ok, err = self:connect():hset(midkey, key, server)
    if err then
        ngx.log(ngx.ERR, "--hset-->   ",ok or "", "  --- ", err or "")
    end

    ok, err = self:connect():expire(midkey, ttl)

    local keykey = keyKeyServer(key) 
    ok, err = self:connect():set(keykey, server, 'EX', ttl)
    if err then
        ngx.log(ngx.ERR, "--hset-->   ", ok or "", "  --- ", err or "")
    end 
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

local mmh2 = require "resty.murmurhash2"
function _M:addServer(server)
    local dateline = ngx.time()
    local key = keyServerOnline(server)
    
    local hash = mmh2(server)
    local val = '{"roomcount":1,"server":"' .. server .. '", "updated": ' .. dateline.. '}'
    return self:connect():hset(key, hash, val)
end


local cjson = require "cjson" 
local pb = require "pb" 
pb.loadfile "/data/web/openresty-im/proto/logic-goim.pb" 

function _M:config(mid, room_id, accepts, room_name) 
    local room_id = "live://1000"
    local key = ngx.md5(mid .. "-web-" .. room_id)
    ngx.log(ngx.ERR, "=======9======>>", mid .. "-web-" .. room_id)
    local data = {
        mid = mid,
        platform = 'web',
        room_id = room_id,
        accepts = "[1000,1001,1002]",
        key = key,
        room_name = room_name,
        url = "ws://192.168.3.222:80/sub"
    } 
    return data
end

function _M:verify(data) 
    local arr = cjson.decode(data)
    local mid = tostring(arr.mid)
    local room_id = arr.room_id
    local key = ngx.md5(mid .. "-web-" .. room_id)
    ngx.log(ngx.ERR, "==>>", mid .. "-web-" .. room_id)
    ngx.log(ngx.ERR, "==>>", key,  "==>>", arr.key)
    if key == arr.key then 
        return true, arr
    end
    
    return false, arr
end 

function _M:publish(typ, room, arr)
    local live = typ .. "://" .. room  
    local msg = cjson.encode(arr) 
    local data = {type = 1, operation = 1000,room = live, msg = msg}
    local message = pb.encode("goim.PushMsg", data) 

    local topic = "goim-push-topic" 
    data = pb.decode("goim.PushMsg", message) 
    self:connect():publish(topic, message)
end
 
function _M:subscribe()   
    local topic = "goim-push-topic"
    return self:connect():subscribe(topic)  
end 

--处理自定义消息类型协议
function _M:msgHandle(data) 
    local arr = pb.decode("goim.PushMsg", data) 
    if not arr then 
        return ''
    end
    return arr.msg
end

return _M