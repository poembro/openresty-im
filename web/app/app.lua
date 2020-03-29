local sfind = string.find
local lor = require("lor.index")
local config  = require("config")  --当前app配置
local cookie_middleware =  require("lor.lib.middleware.cookie")  --cookie开启 
local uploader_middleware = require("web.app.middleware.uploader") --文件上传开启
local login_middleware = require("web.app.middleware.login") --登陆页面验证 与 url 白名单

local app = lor({debug=true}); 
app:conf("view enable", true)   --是否开启视图 往lor/lib/application.lua 下settings属性(table)中放 
app:conf("view engine", config.view_config.engine) --视图引擎
app:conf("view ext", config.view_config.ext)     --视图文件后缀
app:conf("views", config.view_config.views)

--[[
    开启cookie 上传 验证 登陆
--]]
app:use(cookie_middleware());
app:use(uploader_middleware(config.upload_config))-- 文件上传开启
app:use(login_middleware(config.whitelist))-- 登陆页面验证 与 url 白名单

local auth_router = require("web.app.routes.auth")   
local user_router = require("web.app.routes.user")
local upload_router = require("web.app.routes.upload") 
local push_router = require("web.app.routes.push")
local group_router = require("web.app.routes.group")


app:use("/auth", auth_router()) --登录注册都在这里 
app:use("/user", user_router())  --个人中心
app:use("/upload", upload_router()) --上传 
app:use("/group", group_router())  --我的群组
app:use("/push", push_router())   --聊天页面，消息接收
app:get("/about", function(req, res, next)
    res:render("about")
end)
app:get("/error", function(req, res, next)
    res:render("about")
end)

app:get("/", function(req, res, next) 
    return res:redirect("/index")
end)

app:get("/index", function(req, res, next) 
    local me = res.locals.me
    if not me.user_id then
        res:redirect("/auth/login")
    else
	    res:render("index", {me = me})
    end
end)

-- 错误处理中间件
app:erroruse(function(err, req, res, next)
    local hAccept = req.headers["Accept"]
    if req:is_found() ~= true and hAccept then
        if sfind(hAccept, "application/json") then
            res:status(404):json({
                success = false,
                msg = "404! sorry, not found."
            })
        else
            res:status(404):send("404! sorry, not found.")
        end
    end
    
    if hAccept and sfind(hAccept, "application/json") then
        res:status(500):json({
            success = false,
            msg = "500! unknown error65."
        })
    else
        ngx.log(ngx.ERR, err)
        res:status(500):send("unknown error44")
    end
end)

return app