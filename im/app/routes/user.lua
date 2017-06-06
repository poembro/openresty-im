local pairs = pairs
local ipairs = ipairs
local smatch = string.match
local slen = string.len
local utils = require("app.libs.utils")
local Page_utils = require("app.libs.page")
local pwd_secret = require("app.config.config").pwd_secret
local lor = require("lor.index")
local user_model = require("app.model.user")    
local user_router = lor:Router()
 
--[[ 
- @desc   个人资料
- @param  string   url  /user/info  
- return  string   fun  
--]] 
user_router:get("/info", function(req, res, next)
    local userid = req.me.userid
    if not userid then
        return res:json({
            success = false,
            msg = "更改密码前请先登录."
        })
    end
    
    local result, err = user_model:query_by_id(userid) 
    res:render("user/info", {
        userinfo = result
    })
end)



--修改密码
user_router:post("/change_pwd", function(req, res, next)
    local userid = req.me.userid
    if not userid then
        return res:json({
            success = false,
            msg = "更改密码前请先登录."
        })
    end

    local old_pwd = req.body.old_pwd
    local new_pwd = req.body.new_pwd

    local password_len = slen(new_pwd)
    if password_len<6 or password_len>50 then
        return res:json({
            success = false,
            msg = "密码长度应为6~50位."
        })
    end

    local user, err = user_model:query_by_id(userid)
    if not user or err then
       return res:json({
            success = false,
            msg = "无法查找到该用户."
        })
    end  

    if  not user.password or utils.encode(old_pwd .. "#" .. pwd_secret)~=user.password then
        return res:json({
            success = false,
            msg = "输入的当前密码不正确."
        })
    end

    new_pwd = utils.encode(new_pwd .. "#" .. pwd_secret)
    local success = user_model:update_pwd(tonumber(userid), new_pwd)

    if success then
        res:json({
            success = true,
            msg = "更改密码成功."
        })
    else
        res:json({
            success = false,
            msg = "更改密码错误."
        })
    end
end)
-- user setting page stop

 

user_router:post("/info", function(req, res, next)  
    local userid = req.me.userid
    if not userid then
        return res:json({
            success = false,
            msg = "更改密码前请先登录."
        })
    end 
    
   local user, err = user_model:query_by_id(userid)
   if not user or err then
        return res:json({
            success = false,
            msg = "无法查找到该用户."
        })
    end  
    
    local new_pwd = req.body.password 
    local nickname = req.body.nickname 
    local realname = req.body.realname 
    local face = req.body.face 
    local sex = req.body.sex 
    local password_len = slen(new_pwd)
    if password_len >= 6 and password_len <= 50 then --修改密码 
          new_pwd = utils.encode(new_pwd .. "#" .. pwd_secret)
          local success = user_model:update_pwd(tonumber(userid), new_pwd) 
    end

    local success =user_model:update(userid, nickname, realname, face, sex) 
 
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
 
 
--用户列表
user_router:get("/list", function(req, res, next)  
    local page_index = req.query.page or 1  --当前页参数
    local page_size = 10  --每页大小   
     
    local total_count = tonumber( user_model:get_total_count())   --总条数
    local total_count = total_count and tonumber(total_count) or 1
    
    local pageres = {}
    local userall = {}
    if total_count > 0 then  
        pageres = Page_utils.get(total_count, page_size, page_index, req.query);   
        userall = user_model:get_all(1123456, pageres['limit']) 
    end  
 
    res:render("user/list", {
            title = "首页",
            page = pageres, 
            userall = userall
    }) 
end)


user_router:get("/all", function(req, res, next)
    local page_no = req.query.page 
    local page_size = 10  --每页大小  
    local total_count = user_model:get_total_count() 
    local total_page = utils.total_page(total_count, page_size) 
    local userall = user_model:get_all(1123456, page_no, page_size)
  
    res:json({
        success = true,
        data = {
            totalCount = total_count,
            totalPage = total_page,
            currentPage = page_no,
            userall = userall
        }
    })
end)




-- user relation stop

return user_router
