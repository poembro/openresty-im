local protocol = require("comet.app.protocol") 
local push = require("comet.dao.push") 
local BaseAPI = require("comet.base_handler")
local _M = BaseAPI:extend() 
 
_M.ngx_thread_func = function (wb)    
    local data, msgstr, msg
    local reply = push:subscribe()
    while wb.ngx_thread_spawn do
        data = reply()
        if data and data[3] then 
            msgstr = push:msgHandle(data[3])
            msg = protocol:encode(0x10, msgstr)
            if msg ~= "" then
                _M:send(wb, msg, 'binary')
            end
        end
    end

    reply(false)
    wb.ngx_thread_spawn = false 
    ngx.log(ngx.ERR, "--> ngx.thread.spawn stop")
end

function _M:run(wb, data) 
    local packLen, hsize, ver, op, seq, body
    packLen, hsize, ver, op, seq, body = protocol:decode(data)

    ngx.log(ngx.ERR, "--> packLen:", packLen, "<====>",  "hsize:", 
       hsize, "<====>",  "op:", op,  "<====>", "seq:", seq, "<====>", "body:", body)
    
    --heartbeat
    if op == 0x2 then
        self:heartbeat(wb)
    end
    
    --auth
    if op == 0x7 then
        self:auth(wb, body)  
    end
    
    --0x9 原始消息 
end


function _M:auth(wb, body)
    local flag, user = push:verify(body) 
    if not flag then 
        return self:send(wb, 'auth error', 'close')
    end
    
    wb.ctx.user = user
    
    --写入redis 在线
    local mid = user.mid
    local key = user.key
    local server =  ngx.var.server_addr

    push:addMapping(mid, key, server)
   
    local msg = protocol:encode(0x8, "ok")
    self:send(wb, msg, 'binary')
    return flag
end


function _M:heartbeat(wb) 
    local mid = wb.ctx.user.mid
    local key = wb.ctx.user.key

    push:expireMapping(mid, key)

    local msg = protocol:encode(0x3, "")
    self:send(wb, msg, 'binary')
end

return _M