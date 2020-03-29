local pairs = pairs
local ipairs = ipairs
local string = string
local smatch = string.match  

local lor = require("lor.index")
local user_model = require("web.dao.user")

local _M = lor:Router()

--登陆
_M:get("/login", function(req, res, next) 
    res:render("login", {user = 1})
end)

--注册
_M:get("/register", function(req, res, next)  
   return res:render("register", { user = 1 }) 
end)

--处理注册
_M:post("/register", function(req, res, next)
    local dateline = ngx.time();
	local remote_addr = ngx.var.remote_addr
    local nickname = req.body.nickname
    local mobile = req.body.mobile
    local password = req.body.password 
     
    if not mobile or not password or mobile == "" or password == "" then
        return res:json({
            success = false,
            msg = "手机号和密码不得为空."
        })
    end

    local nickname_len = string.len(nickname)
    local mobile_len = string.len(mobile)
    local password_len = string.len(password)

    if nickname_len < 4 or nickname_len > 50 then
        return res:json({
            success = false,
            msg = "昵称长度应为4~50位."
        })
    end
    
    if password_len < 6 or password_len > 50 then
        return res:json({
            success = false,
            msg = "密码长度应为6~50位."
        })
    end

    local match, err = smatch(mobile, "^1[0-9]+$")
    if not match then
       return res:json({
            success = false,
            msg = "手机号只能输入数字，必须以1开头."
        })
    end
    
    local result, err = user_model:query_by_mobile(mobile)
    if result and not err then
        return res:json({
            success = false,
            msg = "手机号已被占用，请修改."
        })
    else
        local snowflake = require "resty.snowflake" 
        local machine_id = 100 --机器编号
        local id_str, timestamp, mid, inc = snowflake.generate_id(machine_id) 
        password = ngx.md5(password .. "#regist") 
        local flag, err = user_model:add(id_str, mobile, password, nickname, remote_addr, dateline)
        if flag and not err then
            return res:json({
                success = true,
                msg = "注册成功."
            })
        else
            return res:json({
                success = false,
                msg = "注册失败."
            })
        end
    end
end)


--处理登录
_M:post("/login", function(req, res, next)
    local mobile = req.body.mobile 
    local password = req.body.password
    
    if not mobile or not password or mobile == "" or password == "" then
        return res:json({
            success = false,
            msg = "手机号和密码不得为空."
        })
    end
    
    password = ngx.md5(password .. "#regist") 
    local user, err = user_model:query_by_mobile(mobile)
    if not err and user and user.password == password then
        local jwt = require("libs.jwt")
        local signVal = jwt:encode(user.user_id, user.nickname, user.mobile, user.face)
        local ok, err = req.cookie.set({
            key = "_TOKEN",
            value = signVal,
            path = "/",
            --domain = "new.cn",
            secure = false, 
            httponly = true,
             --expires =  ngx.cookie_time(os.time() + 3600),
            max_age = 86400, -- 用秒来设置cookie的生存期。
            samesite = "Strict", 
            extension = "a4334aeba444e22222222ce"
        })
        return res:json({success = true,msg = "登录成功."}) 
    else
        return res:json({success = false,msg = "手机号或密码错误，请检查!"})
    end
end)

_M:get("/logout", function(req, res, next)
    local ok, err = req.cookie.set({
        key = "_TOKEN",
        value =  0,
        path = "/",
        --domain = "new.cn",
        secure = false,  
        httponly = true, 
        max_age = -1,  
        samesite = "Strict",  
        extension = "a4334aeba444e22222222ce"   
    })
    res:redirect("/auth/login")
end)

return _M

