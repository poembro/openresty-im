local sfind = string.find
local lor = require("lor.index")
local config  = require("config")  --当前app配置
local cookie_middleware =  require("lor.lib.middleware.cookie")  --cookie开启 
local uploader_middleware = require("api.app.middleware.uploader") --文件上传开启
local login_middleware = require("api.app.middleware.login") --登陆页面验证 与 url 白名单

local app = lor({debug=true}); 
--[[
app:conf("view enable", true)   --是否开启视图 往lor/lib/application.lua 下settings属性(table)中放 
app:conf("view engine", config.view_config.engine) --视图引擎
app:conf("view ext", config.view_config.ext)     --视图文件后缀
app:conf("views", config.view_config.views)
]]

--[[
    开启cookie 上传 验证 登陆
--]]
app:use(cookie_middleware());
app:use(uploader_middleware(config.upload_config))-- 文件上传开启
app:use(login_middleware(config.whitelist))-- 登陆页面验证 与 url 白名单
  
local upload_router = require("api.app.routes.upload")  
local open_router = require("api.app.routes.open")
app:use("/upload", upload_router()) --上传    

app:use("/open", open_router())

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
        ngx.log(ngx.ERR, err)
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
