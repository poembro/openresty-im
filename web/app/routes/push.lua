 
local tonumber = tonumber
local pushmodel = require("comet.dao.push")
local lor = require("lor.index")
local _M = lor:Router()

local group_model = require("web.dao.group") 

--聊天页面 
_M:get("/group", function(req, res, next)
    res:render("push/index", data)
end)
 
-- 返回后端im 服务器地址
_M:post("/group", function(req, res, next)
    local user_id = res.locals.me.user_id 
    local group_id = tonumber(req.body.group_id )
    if group_id == 0 then
        return res:redirect("/index")
        --return res:json({success = false,msg = "参数错误."}) 
    end
    
    local groupinfo, err = group_model:query_by_id(group_id)
    if not groupinfo or err then
        return res:json({
            success = false,
            msg = "不存在该群."
        })
    end

    local arr, err = group_model:in_group(user_id, group_id)
    if not arr or err then
        return res:json({
            success = false,
            msg = "您不在该群."
        })
    end
    
    local data = pushmodel:config(user_id, group_id, group_id, groupinfo.name) 
    return res:json({
        success = true,
        msg = "success.",
        data = data
    })
end)

-- 退出聊天组
_M:get("/info", function(req, res, next) 
    local user_id = res.locals.me.user_id  
    res:render("push/info", {roomid = 111})
end)



--接收消息
_M:post("/main", function(req, res, next)
    local me = res.locals.me
    if not me then
        return res:json({
            success = false,
            msg = "请先登录"
        })
    end 

    local mid = me.user_id
    local nickname = me.nickname
    local mobile = me.mobile
    local face = me.face 

    local dateline = ngx.time()
    local room_id = req.body.room_id 
    local typ = req.body.type 
    local msg = req.body.msg
    -- 需要验证一下 房间权限
    local data = {
        me = {mid = mid, nickname = nickname, mobile = mobile, face = face}, --记录发送人
        type = typ,
        msg = msg,
        room_id = room_id, 
        dateline = dateline
    }
    
    local success =  pushmodel:publish(data) 
     
    if success then
        res:json({
            success = true,
            msg = "发送成功."
        })
    else
        res:json({
            success = false,
            msg = "发送失败~"
        })
    end
end)


return _M
