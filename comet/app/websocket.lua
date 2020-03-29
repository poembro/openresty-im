local server = require "resty.websocket.server"   
local handler = require("comet.app.handler")

local BaseAPI = require("comet.base_handler")
local _M = BaseAPI:extend()

function _M:run() 
    --collectgarbage("collect")
    --local c1 = collectgarbage("count")  
    --心跳包27秒后服务端主动断开   改为60
    local wb, err = server:new({timeout = 60 * 1000, max_payload_len = 65535})
    if not wb then return end 
     
    wb.is_send_lock = false    --发送控制
    wb.ngx_thread_spawn = true --子线程控制
    wb.ctx = {user = {}}
    --注意，无论是croutine.create()创建的常规的Lua coroutine
    --还是由ngx.thread.spawn创建的“轻量级线程”，都是和创建它们的请求绑定的。  
    local co = ngx.thread.spawn(handler.ngx_thread_func, wb)

    local data, typ, err  
    while wb.ngx_thread_spawn do
        data, typ, err = wb:recv_frame()
        if wb.fatal then
            ngx.log(ngx.ERR, '--> wb.fatal :', err)
            break
        end

        while err == "again" do
            local cut_data
            cut_data, typ, err = wb:recv_frame()
            data = (data or '') .. cut_data
        end

        if not data then
            if not string.find(err, "timeout", 1, true) then
                ngx.log(ngx.ERR, '--> 连接异常 :', err)
                break
            end
        end
  
        if typ == "close" then 
            ngx.log(ngx.ERR, '-->  收到close :', err)
            break
        elseif typ == "ping" then 
            ngx.log(ngx.ERR, '-->  收到ping :', err)
        elseif typ == "pong" then
            ngx.log(ngx.ERR, '-->  收到pong:', err)
        elseif typ == 'text' then 
            if data and data ~= "" then
                ngx.log(ngx.ERR, "-->", data)
            end 
        elseif typ == 'binary' then 
            if data then
                handler:run(wb, data) 
            end 
        else
            break
        end
    end  --end while

    wb:send_close(1000, "与服务器断开连接...") 
    wb.ngx_thread_spawn = false
    --ok, err = ngx.thread.kill(co)
    ngx.thread.wait(co)
    --collectgarbage("setpause", 120)
    --local c2 = collectgarbage("count")
    --ngx.log(ngx.ERR, "--> 内存观测: 开始内存为", c1, " 结束内存为", c2)
 
    ngx.log(ngx.ERR, "--> ngx.main.thread stop")
    return true
end



return _M
