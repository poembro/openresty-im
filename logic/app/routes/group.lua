local pairs = pairs
local ipairs = ipairs
local smatch = string.match
local slen = string.len
local page_utils = require("libs.page") 
local lor = require("lor.index")
local group_model = require("logic.dao.group")   
local _M = lor:Router()
 
   

--用户列表
_M:get("/list", function(req, res, next)  
    local user_id = res.locals.me.user_id 
    local page_index = req.query.page or 1  --当前页参数
    local page_size = 10  --每页大小   
     
    local total_count = group_model:get_total_count(0)   --总条数
    total_count = tonumber(total_count)
    
    local pageres = {}
    local arr = {}
    if total_count > 0 then  
        pageres = page_utils.get(total_count, page_size, page_index, req.query)
        arr = group_model:get_all(0, pageres['limit'])
    end
     
    res:render("group/list", {title = "首页", page = pageres, arr = arr}) 
end)


-- user relation stop
return _M
