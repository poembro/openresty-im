local DB = require("libs.db")
local db = DB:new()

local _M = {}
  
 
--检查是否组成员
function _M:in_group(user_id, group_id)
    local result, err =  db:query("select * from mg_group_user where user_id=? and group_id=? limit 1",
         {user_id, group_id})
    if not result or err or type(result) ~= "table" or #result ~=1 then
        return nil, err
    else
        return result[1], err
    end
end

function _M:add(user_id, group_id, label, dateline ) 
    return db:query("insert into mg_group_user(user_id, group_id, label,dateline) values(?,?,?,?)",
            {user_id, group_id, label, dateline})
end

function _M:query_by_id(group_id)
    local result, err =  db:query("select * from mg_group where group_id=?", {group_id})
    if not result or err or type(result) ~= "table" or #result ~=1 then
        return nil, err
    else
        return result[1], err
    end
end
 
--总条数
function _M:get_total_count(id)
    local res, err = db:query("select count(id) as c from mg_group where id > ? limit 1",{id})
    if err or not res or #res~=1 or not res[1].c then
        return 0
    else
        return res[1].c
    end
end
 
--我加入的所有群
function _M:get_all(id, limits)
    local res, err = db:query("select * from mg_group where id > ?  LIMIT " .. limits, {id})
	if not res or err or type(res) ~= "table" or #res <= 0 then
		return {}
	else
		return res
	end
end

return _M
