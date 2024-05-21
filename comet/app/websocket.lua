local string_find = string.find
local server = require "resty.websocket.server"   
local handler = require("comet.app.handler")
local BaseAPI = require("comet.app.base_handler")
local _M = BaseAPI:extend()

function _M:run() 
    --collectgarbage("collect")
    --local c1 = collectgarbage("count")  
    local wb, err = server:new({timeout = 60, max_payload_len = 65535})
    if not wb then return end 
     
    wb.ctx = {user = {}}
    --注意，无论是croutine.create()创建的常规的Lua coroutine
    --还是由ngx.thread.spawn创建的“轻量级线程”，都是和创建它们的请求绑定的。  
    local co = ngx.thread.spawn(handler.ngx_thread_func, wb)

    local data, typ, err, bytes
    while true do
        data, typ, err = wb:recv_frame()
        if wb.fatal then
            ngx.log(ngx.ERR, '--> err fatal ', err)
            break
        end

        while err == "again" do
            local cut_data
            cut_data, typ, err = wb:recv_frame()
            data = (data or '') .. cut_data
        end

        if not data and err and not string_find(err, "timeout", 1, true) then
            ngx.log(ngx.ERR, '--> conn err ', err)
            break 
        end

        if typ == "close" then 
            break
        elseif typ == "ping" then 
            bytes, err = self:send(wb, "", "pong")
            if not bytes then
                ngx.log(ngx.ERR, "failed to send frame: ", err)
                break
            end
        elseif typ == "pong" then
            bytes, err = self:send(wb, "", "ping")
            if not bytes then
                ngx.log(ngx.ERR, "failed to send ping frame: ", err)
                break
            end
        elseif typ == 'binary' then 
            if data then
                handler:run(wb, data) 
            end
        else
            break --exit
        end
    end  --end while

    self:send(wb, "与服务器断开连接...", "close")
    ok, err = ngx.thread.kill(co)
    if !ok then
        ngx.log(ngx.ERR, '--> err fatal ', err)
    end 
    --ngx.thread.wait(co)
    --collectgarbage("setpause", 120)
    --local c2 = collectgarbage("count")
    --ngx.log(ngx.ERR, "--> 内存观测: 开始内存为", c1, " 结束内存为", c2)
    ngx.log(ngx.ERR, "--> ngx.main.thread stop")
    return true
end



return _M
