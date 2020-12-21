local push = require("comet.dao.push")
local protocol = require("libs.protocol") 
local BaseAPI = require("comet.app.base_handler")
local _M = BaseAPI:extend() 

local OpHeartbeat = 0x2
local OpHeartbeatReply = 0x3
local OpSendMsg = 0x4
local OpSendMsgReply = 0x5
local OpAuth = 0x7
local OpAuthReply = 0x8
local OpSync = 14
local OpSyncReply = 15
local OpSeq = 16
local OpSeqReply = 17

_M.ngx_thread_func = function (wb) 
    local data, msgstr, msg
    local reply = push:subscribe() 

    while wb.ngx_thread_spawn do
        data = reply()
        if data and data[3] then 
            msgstr = push:dispatch(wb.ctx.user, data[3])
            if msgstr then 
                msg = protocol:encode(OpSendMsgReply, msgstr)
                _M:send(wb, msg, 'binary')
            end
        end
    end

    reply(false)
    wb.ngx_thread_spawn = false 
    ngx.log(ngx.DEBUG, "--> ngx.thread.spawn stop")
end

function _M:run(wb, data) 
    local packLen, hsize, ver, op, seq, body
    packLen, hsize, ver, op, seq, body = protocol:decode(data)

    --ngx.log(ngx.DEBUG, "--> packLen:", packLen, "<====>", 
    --     "hsize:", hsize, "<====>",  "op:", op, 
    --        "<====>", "seq:", seq, "<====>", "body:", body)

    --auth
    if op == OpAuth then
        self:auth(wb, body, OpAuthReply)
    end
    
    --heartbeat
    if op == OpHeartbeat then
        self:heartbeat(wb, OpHeartbeatReply)
    end
    
    --sync 同步历史消息
    if op == OpSync then
        self:sync(wb, OpSyncReply)
    end

    -- ack Seq
    if op == OpSeq then
        self:seq(wb, body, OpSeqReply)
    end 
end


function _M:seq(wb, body, op)
    local mid = wb.ctx.user.mid
    local shop_id = wb.ctx.user.shop_id
    local key = wb.ctx.user.key  
    local room_id = wb.ctx.user.room_id 
 
    if body and tonumber(body) > 0 then
        -- 提升一下排序 
        push:addUserList(shop_id, mid) 
        -- 添加偏移 
        push:addSeq(mid, room_id, body) 
    end
    
    local msg = protocol:encode(op, body)
    self:send(wb, msg, 'binary')
end


function _M:heartbeat(wb, op) 
    local mid = wb.ctx.user.mid
    local key = wb.ctx.user.key

    push:expireMapping(mid, key)
 
    local msg = protocol:encode(op, "")
    self:send(wb, msg, 'binary')
end

function _M:auth(wb, body, op)
    local flag, user = push:verify(body) 
    if not flag then 
        self:send(wb, 'auth error', 'close')
        return false
    end
    
    wb.ctx.user = user
    
    local msg = protocol:encode(op, "ok")
    self:send(wb, msg, 'binary')
    return true
end


local reverse = function (reverseTab)
    local tmp = {}
    for i = 1, #reverseTab do
        local key = #reverseTab + 1 - i
        tmp[i] = reverseTab[key]
    end
    return tmp
end

-- 同步历史消息
function _M:sync(wb, op) 
    local room_id = wb.ctx.user.room_id
    local arr = push:findMsgList(room_id, 0, 25)
    if #arr > 0 then
        arr = reverse(arr)
    end
    
    local msg
    for _, value in ipairs(arr) do
        if value and value ~= "" then
            msg = protocol:encode(op, value)
            self:send(wb, msg, 'binary')
        end
    end
end

 

return _M
