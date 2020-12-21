local ngx = ngx 
local string_format = string.format
local default = require("config").default
local snowflake = require "resty.snowflake" 
local machine_id = 99 --机器编号
local lor = require("lor.index")
local _M = lor:Router()

local dao = require("comet.dao.push")
--[[
业务流程
1.点击页面 咨询 按钮
2.前提是 商户服务器 拼接好 href = /open/im?  补充一下 参数 给到静态页面参数
3.访问到聊天静态页面
4.每个用户都是临时用户  发送的消息最终到达商户总的消息库
5.拿到/open/group 的返回值 开始建立聊天
]]--
local shell = require "resty.shell"
local send = function (id)
    local timeout = 1000  -- ms
    local max_size = 4096  -- byte

    local cmd = string_format(default.notic, id)
    local ok, stdout, stderr, reason, status = shell.run(cmd, nil, timeout, max_size)

    ngx.log(ngx.ERR, "-->  id:",id, "  -->",(ok or "") ,"   -->", stdout or "")
    return true
end

-- 用户界面
-- shop_id 商户号 必传
-- shop_name 商户名 非必传
-- shop_face 商户头像 非必传
-- mid      用户id 非必传(随机生成)
-- nickname 用户昵称 非必传(随机生成)
-- face     用户头像 非必传
-- url      跳转回用户界面 非必传 涉及授权后跳转回用户界面 (如果用户有自定义界面的话 必传)
_M:get("/im", function(req, res, next)
    local id_str = dao:createMid()
 --   send(id_str)
    local url = req.query.url or default.redirect301   -- 跳回到商户去的网页地址
    local shop_id = req.query.shop_id or default.shop_id  -- 商户号 
    local mid = req.cookie.get("mid") or req.query.mid or id_str --用户id user_id
    local nickname = req.query.nickname or "新人-" .. mid --用户名称
    local face = req.query.face or default.face  --用户头像 
    local room_id, keyRoomId = dao:acceptRoom(shop_id, mid)
    local accepts = "[" .. room_id .. ",".. shop_id ..",10000]"  -- 接收他自己的频道 接收商户频道 接收系统频道
    
    local tbl = {
        room_id = keyRoomId,  --接收指定房间号
        accepts = accepts, --允许接收哪些房间消息 1000表示系统级别频道的消息
        key = dao:createKey(keyRoomId, mid), --key 设备id
        
        mid = mid, --用户id
        nickname = ngx.escape_uri(nickname), --用户名称
        face = face, --用户头像

        shop_id = shop_id, --消息要存到指定商户
        shop_name = ngx.escape_uri("客服"),
        shop_face = default.shop_face,

        platform = 'web', 
        suburl = default.suburl,
        pushurl = default.pushurl,
        
        referer = ngx.var.http_referer,
    }

    local query = ngx.encode_args(tbl)
    --ngx.log(ngx.ERR, query)
    res:redirect(url .. query, 301)
end)

--商户界面
-- shop_id 商户号 必传
-- shop_name 商户名 必传
-- shop_face 商户头像 必传
-- mid      用户id 非必传(随机生成)
-- nickname 用户昵称 非必传(随机生成)
-- face     用户头像 非必传
-- url      跳转回用户界面 非必传 涉及授权后跳转回用户界面 (如果用户有自定义界面的话 必传)
_M:get("/com", function(req, res, next)
    local id_str = dao:createMid()
    local seq = req.query.seq or 0

    local url = req.query.url or default.redirect301   -- 跳回到商户去的网页地址
    local shop_id = req.query.shop_id or default.shop_id  -- 商户号 
    local shop_name = req.query.shop_name or "客服-" .. id_str
    local shop_face = req.query.shop_face or default.shop_face 
 
    local mid = req.query.mid or id_str --用户id user_id
    local nickname = req.query.nickname or "新人-".. id_str --用户名称
    local face = req.query.face or default.face  --用户头像

    local room_id, keyRoomId = dao:acceptRoom(shop_id, mid)
    local accepts = "[" .. room_id .. ",".. shop_id ..",10000]"  -- 接收他自己的频道 接收商户频道 接收系统频道
    
    local tbl = {
        room_id = keyRoomId,  --接收指定房间号
        accepts = accepts, --允许接收哪些房间消息 1000表示系统级别频道的消息
        key = dao:createKey(keyRoomId, shop_id), --key 设备id

        mid = shop_id, --用户id(这里是商户去跟指定用户聊天  所以它本人是商户id)
        nickname = ngx.escape_uri(shop_name), --用户名称
        face = shop_face, --用户头像

        shop_id = mid, --消息要存到指定商户
        shop_name = ngx.escape_uri(nickname),
        shop_face = face,

        platform = 'web', 
        suburl = default.suburl,
        pushurl = default.pushurl,
    }
    -- 将未读更新
    --ngx.log(ngx.ERR, "--/open/com?-seq--->", seq)
    if seq and seq ~= "" and seq ~= "undefined" and tonumber(seq) > 0 then
        dao:addSeq(shop_id, keyRoomId, tostring(seq))
        --ngx.log(ngx.ERR, "--/open/com?22222-seq--->", seq)
    end
    
    local query = ngx.encode_args(tbl)
    res:redirect(url .. query, 301)
end)


--接收所有消息
_M:post("/push", function(req, res, next)
    local dateline = ngx.time()
    local id_str, timestamp, mid2, inc = snowflake.generate_id(machine_id)
    local mid = req.query.mid
    local shop_id = req.query.shop_id

    local typ = req.body.type 
    local msg = req.body.msg
    local room_id = req.body.room_id 
    local _, keyRoomId = dao:acceptRoom(shop_id, mid)
    if room_id ~= keyRoomId then 
        return res:json({
            success = false,
            msg = "参数错误,发送失败~"
        })
    end

    -- 需要验证一下 房间权限
    local data = {
        --记录发送人
        mid = mid,
        shop_id = shop_id,
        type = typ,
        msg = msg,
        room_id = keyRoomId, 
        dateline = dateline,
        id = id_str,
    }
    
    local success = dao:publish(data) 
    
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

-- 某商户下所有用户
_M:post("/finduserlist", function(req, res, next)
    local flag = tonumber(req.query.flag or 0)
    local shop_id = tonumber(req.query.shop_id) 
    local data, success 
    if flag < 1 then
        data, success = dao:findUserList(shop_id) 
    else
        data, success = dao:findUserStatus(shop_id)
    end
    if success then
        res:json({
            success = true,
            msg = "发送成功.",
            data = data
        })
    else
        res:json({
            success = false,
            msg = "发送失败~"
        })
    end
end)


-- 某商户下所有用户
_M:get("/del", function(req, res, next)
    local data, success = dao:delSysTotal()
    if success then
        res:json({
            success = true,
            msg = "发送成功.",
            data = data
        })
    else
        res:json({
            success = false,
            msg = "发送失败~"
        })
    end
end)

return _M
