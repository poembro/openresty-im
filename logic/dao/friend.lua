local DB = require("libs.db")
local db = DB:new()

local _M = {}
 
function _M:add(user_id, friend_id, label)  
    return db:query("insert into mg_friend(user_id, friend_id, label) values(?,?,?)",
    {user_id, friend_id, label })
end 

--检查是否好友
function _M:is_friend(user_id, friend_id)
    local result, err =  db:query("select * from mg_friend where user_id=? and friend_id=? limit 1", {user_id, friend_id})
    if not result or err or type(result) ~= "table" or #result ~=1 then
        return nil, err
    else
        return result[1], err
    end
end

function _M:get_total_count(user_id)
    local res, err = db:query("select count(user_id) as c from mg_friend where user_id =? limit 1", {user_id})
    if err or not res or #res~=1 or not res[1].c then
        return 0
    else
        return res[1].c
    end
end
 
 
function _M:get_all(user_id, limits)
    local res, err = db:query("select * from mg_friend where user_id =? LIMIT " .. limits, {user_id})
	if not res or err or type(res) ~= "table" or #res <= 0 then
		return {}
	else
		return res
	end
end

return _M
