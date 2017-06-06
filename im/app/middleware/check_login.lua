local smatch = string.match
local sfind = string.find
local utils = require("app.libs.utils")
local pwd_secret = require("app.config.config").pwd_secret
  
local function is_login(req)   
    if req.cookie then
        local str = req.cookie.get("user") 
        if not str or str == "" then  
           return false, nil
        end 
          
       local userinfo = utils.string_split(utils.decrypted(str, pwd_secret), '--||')
         
        if userinfo and userinfo[1] and userinfo[2] then 
             local user = {userid = userinfo[1], username= userinfo[2], create_time = userinfo[3]};  
            -- ngx.ctx['me'] = user;
             req.me = user;
            return true, user
        end
    end
    
    return false, nil
end

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

        local islogin, user= is_login(req)

        if in_white_list then
            res.locals.login = islogin
            res.locals.username = user and user.username
            res.locals.userid = user and user.userid
            res.locals.create_time = user and user.create_time
            next()
        else
            if islogin then
                res.locals.login = true
                res.locals.username = user.username
                res.locals.userid = user.userid
                res.locals.create_time = user.create_time
                next()
            else
                if sfind(req.headers["Accept"], "application/json") then
                    res:json({
                        success = false,
                        msg = "该操作需要先登录."
                    })
                else
                    res:redirect("/auth/login")
                end
            end
        end
    end
end

return check_login

