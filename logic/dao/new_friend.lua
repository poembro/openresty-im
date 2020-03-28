local DB = require("libs.db")
local db = DB:new()

local _M = {}
  
--申请为好友 
function _M:add(user_id, friend_id, status, label, dateline)  
    return db:query("insert into mg_new_friend(user_id, friend_id, status, label, dateline) values(?,?,?,?,?)",
            {user_id, friend_id, status, label, dateline})
end

--确认好友关系
function _M:confirm(user_id, friend_id, status, label, dateline, nickname)  
    return db:query("insert into mg_new_friend(user_id, friend_id, status, label, dateline) values(?,?,?,?,?)",
            {user_id, friend_id, status, label, dateline}) 
end

--确认成为好友是判断一下
function _M:is_new_friend(user_id, friend_id)
    local result, err =  db:query("select * from mg_new_friend where user_id=? and friend_id=? and status!=0 limit 1", {user_id, friend_id})
    if not result or err or type(result) ~= "table" or #result ~=1 then
        return nil, err
    else
        return result[1], err
    end
end

function _M:get_total_count(friend_id)
    local res, err = db:query("select count(user_id) as c from mg_new_friend where friend_id=? limit 1", {friend_id})
    if err or not res or #res~=1 or not res[1].c then
        return 0
    else
        return res[1].c
    end
end
 
 
function _M:get_all(friend_id, limits)
    local res, err = db:query("select * from mg_new_friend where friend_id=? LIMIT " .. limits, {friend_id})
	if not res or err or type(res) ~= "table" or #res <= 0 then
		return {}
	else
		return res
	end
end

return _M
