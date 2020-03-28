local pairs = pairs
local ipairs = ipairs
local smatch = string.match
local slen = string.len
local utils = require("libs.utils")
local Page_utils = require("libs.page")
local pwd_secret = require("config.config").pwd_secret
local lor = require("lor.index")
local user_model = require("logic.dao.user")    
local _M = lor:Router()
 
 

_M:get("/index", function(req, res, next)
    local uid = res.locals.me.user_id
    
    local result, err = user_model:query_by_id(uid) 
    res:render("user/index", {
        userinfo = result
    })
end)

--[[ 
- @desc   个人资料
- @param  string   url  /user/info  
- return  string   fun  
--]] 
_M:get("/info", function(req, res, next)
    local uid = res.locals.me.user_id
    
    local result, err = user_model:query_by_id(uid) 
    res:render("user/info", {
        userinfo = result
    })
end)

 
_M:post("/info", function(req, res, next)
    local uid = res.locals.me.user_id 
    
   local user, err = user_model:query_by_id(uid)
   if not user or err then
        return res:json({
            success = false,
            msg = "无法查找到该用户."
        })
    end  
    
    local new_pwd = req.body.password 
    local nickname = req.body.nickname 
    local realname = req.body.realname or ""
    local face = req.body.face 
    local sex = req.body.sex 
    local password_len = slen(new_pwd)
    if password_len >= 6 and password_len <= 50 then --修改密码  
          new_pwd = ngx.md5(new_pwd .. "#regist") 
          local success = user_model:update_pwd(uid, new_pwd) 
    end

    local success = user_model:update(uid, nickname, realname, face, sex)  
    if success then
        res:json({
            success = true,
            msg = "更改成功."
        })
    else
        res:json({
            success = false,
            msg = "更改错误."
        })
    end
end)
 
local function dump(v)
    local __dump 
    if not __dump then
        __dump = function (v, t, p)    
            local k = p or "";

            if type(v) ~= "table" then
                table.insert(t, k .. " : " .. tostring(v));
            else
                for key, value in pairs(v) do
                    __dump(value, t, k .. "[" .. key .. "]");
                end
            end
        end
    end

    local t = {"\r\n" ..'/*************** 调试日志 **************/' };
    __dump(v, t);
    print(table.concat(t, "\r\n"));
end
 

-- user relation stop
return _M
