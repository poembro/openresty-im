local pairs = pairs
local ipairs = ipairs
local smatch = string.match 
  
local cjson = require("cjson")
local utils = require("app.libs.utils")
local pwd_secret = require("app.config.config").pwd_secret
local lor = require("lor.index")
local user_model = require("app.model.user")

local auth_router = lor:Router()
  
 
--[[
- @desc  测试
- @param  path            string   路径
- @param  fn             function  匿名函数 
- return  json
--]]
auth_router:get("/test", function(req, res, next) 
    local result, err = user_model:query_by_id(6) 
    res:json({
        success = true,
        data = { 
            res = result
        }
    })
end)

--登陆
auth_router:get("/login", function(req, res, next) 
    res:render("login", {
        user = 1
    })
end)

--注册
auth_router:get("/register", function(req, res, next)  
   return  res:render("register", { user = 1 }) 
end)

--处理注册
auth_router:post("/register", function(req, res, next)
    local nickname = req.body.nickname
    local mobile = req.body.mobile 
    local password = req.body.password
 
    local pattern = "^1[0-9]+$"
    local match, err = smatch(mobile, pattern)

    if not mobile or not password or mobile == "" or password == "" then
        return res:json({
            success = false,
            msg = "手机号和密码不得为空."
        })
    end

    local nickname_len = string.len(nickname)
    local mobile_len = string.len(mobile)
    local password_len = string.len(password)

    if nickname_len < 4 or  nickname_len>50 then
        return res:json({
            success = false,
            msg = "昵称长度应为4~50位."
        })
    end
    
    if password_len<6 or password_len>50 then
        return res:json({
            success = false,
            msg = "密码长度应为6~50位."
        })
    end

    if not match then
       return res:json({
            success = false,
            msg = "手机号只能输入数字，必须以1开头."
        })
    end

    local result, err = user_model:query_by_username(mobile)
    local isExist = false
    if result and not err then
        isExist = true
    end

    if isExist == true then
        return res:json({
            success = false,
            msg = "手机号已被占用，请修改."
        })
    else
        password = utils.encode(password .. "#" .. pwd_secret)
        local avatar = string.sub(mobile, 1, 1) .. ".png" --取首字母作为默认头像名
        avatar = string.lower(avatar)
        local result, err = user_model:new(mobile, password, nickname)
        if result and not err then
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
auth_router:post("/login", function(req, res, next)
    local mobile = req.body.mobile 
    local password = req.body.password

    if not mobile or not password or mobile == "" or password == "" then
        return res:json({
            success = false,
            msg = "手机号和密码不得为空."
        })
    end

    local isExist = false --用户是否存在
    local userid = 0  --用户uid

    password = utils.encode(password .. "#" .. pwd_secret)
    local result, err = user_model:query(mobile, password)

    local user = {}
    if result and not err then
        if result and #result == 1 then
            isExist = true
            user = result[1] 
            userid = user.uid
        end
    else
        isExist = false
    end

                
    local g = userid..'--||'.. mobile ..'--||'.. (user.regtime or "")
    local signVal = utils.encrypted(g, pwd_secret)
     
    if isExist == true then  
         local ok, err = req.cookie.set({
            key = "_TOKEN",
            value = signVal,
            path = "/",
            --domain = "new.cn",
            secure = false, --设置后浏览器只有访问https才会把cookie带过来,否则浏览器请求时不带cookie参数
            httponly = true, --设置后js 无法读取
             --expires =  ngx.cookie_time(os.time() + 3600),
            max_age = 86400, --用秒来设置cookie的生存期。
            samesite = "Strict",  --或者 Lax 指a域名下收到的cookie 不能通过b域名的表单带过来
            extension = "a4334aeba444e22222222ce"  --设置好像没起什么作用 
        })
        return res:json({success = true,msg = "登录成功."})
   
    else
        return res:json({success = false,msg = "手机号或密码错误，请检查!"})
    end
end)


auth_router:get("/logout", function(req, res, next)
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


return auth_router

