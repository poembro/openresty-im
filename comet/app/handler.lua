local push = require("comet.dao.push")
local protocol = require("comet.app.protocol") 
local BaseAPI = require("comet.app.base_handler")
local _M = BaseAPI:extend() 


local OpHeartbeat = 0x2
local OpHeartbeatReply = 0x3
local OpAuth = 0x7
local OpAuthReply = 0x8
local OpSubReply = 0x15


_M.ngx_thread_func = function (wb) 
    local data, msgstr, msg
    local reply = push:subscribe() 

    while wb.ngx_thread_spawn do
        data = reply()
        if data and data[3] then 
            msgstr = push:dispatch(wb.ctx.user, data[3])
            if msgstr then 
                msg = protocol:encode(OpSubReply, msgstr)
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

    -- ngx.log(ngx.ERR, "--> packLen:", packLen, "<====>", "hsize:", hsize, "<====>",  "op:", op,  "<====>", "seq:", seq, "<====>", "body:", body)
    
    --heartbeat
    if op == OpHeartbeat then
        self:heartbeat(wb)
    end
    
    --auth
    if op == OpAuth then
        self:auth(wb, body)  
    end
    
    --0x9 原始消息 
end

function _M:heartbeat(wb) 
    local mid = wb.ctx.user.mid
    local key = wb.ctx.user.key

    push:expireMapping(mid, key)

    local msg = protocol:encode(OpHeartbeatReply, "")
    self:send(wb, msg, 'binary')
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
    local server = ngx.var.server_addr

    push:addMapping(mid, key, server)
   
    local msg = protocol:encode(OpAuthReply, "ok")
    self:send(wb, msg, 'binary')
    return flag
end

return _M