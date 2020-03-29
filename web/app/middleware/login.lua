local smatch = string.match
local sfind = string.find

local jwt = require("libs.jwt")


--[[
- @desc      检查是否登录
- @param  table   whitelist   不检查的url  
- return  返回true or false
--]]
local function check_login(whitelist)
    return function(req, res, next)
        local requestPath = req.path
        local in_white_list = false
        if requestPath == "/" then
            in_white_list = true
        else
            for i, v in ipairs(whitelist) do
                local match, err = smatch(requestPath, v)
                if match then
                    in_white_list = true
                end
            end
        end
 
        if in_white_list then 
            next()
        else
            local toekn = req.cookie.get("_TOKEN")
            local user = jwt:decode(toekn)
            if toekn and user then
                res.locals.me = user 
                next()
            else
                if sfind(req.headers["Accept"], "application/json") then
                    res:json({ success = false, msg = "该操作需要先登录." })
                else
                    res:redirect("/auth/login")
                end
            end
        end
    end
end

return check_login

