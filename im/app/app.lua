local sfind = string.find
local lor = require("lor.index")
local config  = require("app.config.config")  --当前app配置
--local session_middleware = require("lor.lib.middleware.session") --session开启
local cookie_middleware =  require("lor.lib.middleware.cookie")  --cookie开启 
local uploader_middleware = require("app.middleware.uploader") --文件上传开启
local check_login_middleware = require("app.middleware.check_login") --登陆页面验证 与 url 白名单
local reponse_time_middleware = require("app.middleware.response_time")  -- 过滤器:添加响应头 


local app = lor(); 
app:conf("view enable", true)   --是否开启视图 往lor/lib/application.lua 下settings属性(table)中放 
app:conf("view engine", config.view_config.engine) --视图引擎
app:conf("view ext", config.view_config.ext)     --视图文件后缀
app:conf("views", config.view_config.views)

--[[
    开启session cookie 上传 验证 登陆
--]]
--app:use(session_middleware());
app:use(cookie_middleware());
app:use(uploader_middleware(config.upload_config))-- 文件上传开启
app:use(check_login_middleware(config.whitelist))-- 登陆页面验证 与 url 白名单

app:use(reponse_time_middleware({  -- 过滤器:添加响应头
    digits = 0,
    header = 'X-Response-Time',
    suffix = true
}))

app:use(function(req, res, next)
    res:set_header('X-Powered-By', 'Lor Framework') 
    next()
end)

local auth_router = require("app.routes.auth")  
local error_router = require("app.routes.error")
local user_router = require("app.routes.user")
local upload_router = require("app.routes.upload")
local im_router = require("app.routes.im")

app:use("/auth", auth_router())--登录注册都在这里
app:use("/error", error_router())
app:use("/user", user_router())  --个人中心
app:use("/upload", upload_router()) --上传
app:use("/im", im_router()) --聊天

app:get("/", function(req, res, next) 
    return res:redirect("/index")
end) 

app:get("/index", function(req, res, next) 
    local userid = tonumber(req.me.userid) 
    if not userid or userid < 1  then
         res:redirect("/auth/login")
    else 
	     res:render("index", {user = 2})
    end
end)

app:get("/about", function(req, res, next)
    res:render("about")
end)

-- 404 error 
-- 错误处理中间件
app:erroruse(function(err, req, res, next)
    if req:is_found() ~= true then
        if sfind(req.headers["Accept"], "application/json") then
            res:status(404):json({
                success = false,
                msg = "404! sorry, not found."
            })
        else
            res:status(404):send("404! sorry, not found.")
        end
    end
    
    if sfind(req.headers["Accept"], "application/json") then
        res:status(500):json({
            success = false,
            msg = "500! unknown error65."
        })
    else
        res:status(500):send("unknown error44")
    end
end)

return app;