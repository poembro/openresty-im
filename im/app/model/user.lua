local DB = require("app.libs.db")
local db = DB:new()

local user_model = {}
 
function user_model:new(mobile, password, nickname)
	local time_last_msg = ngx.time();
	local remote_addr = ngx.var.remote_addr
    return db:query("insert into mg_user_member(mobile, password, regtime, nickname,regip) values(?,?,?,?,?)",
            {mobile, password, time_last_msg, nickname,remote_addr})
end

-- return user, err
function user_model:query_by_username(mobile)
   	local res, err =  db:query("select * from mg_user_member where mobile=? limit 1", {mobile})
   	if not res or err or type(res) ~= "table" or #res ~=1 then
		return nil, err or "error"
	end

	return res[1], err
end

function user_model:query_ids(usernames)
   local res, err =  db:query("select id from mg_user_member where username in(" .. usernames .. ")")
   return res, err
end

function user_model:query(mobile, password)
   local res, err =  db:query("select * from mg_user_member where mobile=? and password=?", {mobile, password})
   return res, err
end

function user_model:query_by_id(id)
    local result, err =  db:query("select * from mg_user_member where uid=?", {tonumber(id)})
    if not result or err or type(result) ~= "table" or #result ~=1 then
        return nil, err
    else
        return result[1], err
    end
end


function user_model:update_face(userid, avatar)
    db:query("update mg_user_member set face=? where uid=?", {avatar, userid})
end
 
--只修改密码
function user_model:update_pwd(userid, pwd)
    local res, err = db:query("update mg_user_member set password=? where uid=?", {pwd, userid})
    if not res or err then
        return false
    else
        return true
    end

end
 
--只修多个字段内容
function user_model:update(userid, nickname, realname, face, sex)
    local res, err = db:query("update mg_user_member set nickname=?, realname=?, face=?,sex=? where uid=?", 
        { nickname, realname, face, sex, userid})

    if not res or err then
        return false
    else
        return true
    end
end



function user_model:get_total_count()
    local res, err = db:query("select count(uid) as c from mg_user_member")

    if err or not res or #res~=1 or not res[1].c then
        return 0
    else
        return res[1].c
    end
end
 
 
function user_model:get_all(option, limits) 
    
    local res, err = db:query("select * from mg_user_member LIMIT " .. limits) 
	if not res or err or type(res) ~= "table" or #res <= 0 then
		return {}
	else
		return res
	end
end


return user_model
