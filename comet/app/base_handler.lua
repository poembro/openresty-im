require "resty.core" 
local ngx_time = ngx.time
local Object = require("libs.classic")
local resty_lock = require "resty.lock"

local _M = Object:extend()

function _M:new(name)
    self._name = name
end

--处理websocket协议
function _M:send(wb, msg, typ)
    local lock, err = resty_lock:new("ngx_locks",{exptime=30,timeout=5,step=0.001,ratio=2,max_step=0.5})
    if not lock then
        -- ngx.say("failed to create lock: ", err)
        return false, "lock"
    end
    local elapsed, err = lock:lock("lock" .. wb.ctx.user.key)
    if not elapsed then
        -- fail("failed to acquire the lock: ", err)
        return false, "lock"
    end
 
    local res, err 
    if typ == nil or typ == "text" then
        res, err = wb:send_text(msg)  
    elseif typ == "ping" then
        res, err = wb:send_ping(msg) 
    elseif typ == "pong" then
        res, err = wb:send_pong(msg)
    elseif typ == "binary" then  
        res, err = wb:send_binary(msg)
    elseif typ == "close" then
        res, err = wb:send_close(1000, msg)
    end
     
    lock:unlock()
    return res, err
end

return _M
