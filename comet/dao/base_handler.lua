require "resty.core"  
local rds = require "libs.iredis"
local config = require("config") 
local Object = require("libs.classic")
local _M = Object:extend()

function _M:new(name)
    self._name = name
end

--处理websocket协议
local instanse = nil

function _M:connect() 
    if not instanse then
        local conf = config.redis 
        --ngx.log(ngx.ERR, "--> new redis ")
        instanse = rds:new(conf) 
    end
    
    return instanse
end

--[[
local pb = require "pb" 
pb.loadfile "/data/web/openresty-im/proto/logic-goim.pb" 

function _M:publish(typ, room_id, arr)
    local room_id = keyRoomId(typ, room_id) 
    local msg = cjson.encode(arr) 
    local data = {type = 1, operation = 1000,room = room_id, msg = msg}
    local message = pb.encode("goim.PushMsg", data) 

    local topic = "goim-push-topic"  
    self:connect():publish(topic, message)
end
 
function _M:subscribe()   
    local topic = "goim-push-topic"
    return self:connect():subscribe(topic)  
end 

--处理自定义消息类型协议
function _M:dispatch(user, data) 
    local arr = pb.decode("goim.PushMsg", data) 
    if not arr then 
        return ''
    end
    
    return arr.msg
end
--]]


return _M
