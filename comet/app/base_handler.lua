require "resty.core" 
local ngx_time = ngx.time
local Object = require("libs.classic")
local _M = Object:extend()

function _M:new(name)
    self._name = name
end

--处理websocket协议
function _M:send(wb, msg, typ)
    local res, err
    
    if wb.is_send_lock then
       return false, "lock"
    end
    
    wb.is_send_lock = true
    
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
    
    wb.is_send_lock = false 
    return res, err
end



return _M
