local DB = require("libs.db")
local db = DB:new()

local _M = {}
 
function _M:add(user_id, mobile, password, nickname, regip, regtime)
    local face = "/static/wap/img/portrait.jpg"
    return db:query("insert into mg_user(user_id, mobile, password, face, regtime, nickname,regip) values(?,?,?,?,?,?,?)",
            {user_id, mobile, password, face, regtime, nickname, regip})
end

function _M:query_by_mobile(mobile)
   	local res, err =  db:query("select * from mg_user where mobile=? limit 1", {mobile})
   	if not res or err or type(res) ~= "table" or #res ~=1 then
		return nil, err or "error"
	end

	return res[1], err
end


function _M:query_by_id(id)
    local result, err =  db:query("select * from mg_user where user_id=?", {id})
    if not result or err or type(result) ~= "table" or #result ~=1 then
        return nil, err
    else
        return result[1], err
    end
end

function _M:update_face(user_id, avatar)
    db:query("update mg_user set face=? where user_id=?", {avatar, user_id})
end

--只修改密码
function _M:update_pwd(user_id, pwd)
    local res, err = db:query("update mg_user set password=? where user_id=?", {pwd, user_id})
    if not res or err then
        return false
    else
        return true
    end
end

--只修多个字段内容
function _M:update(user_id, nickname, realname, face, sex)
    local res, err = db:query("update mg_user set nickname=?, realname=?, face=?,sex=? where user_id=?", 
        { nickname, realname, face, sex, user_id})
    if not res or err then
        return false
    else
        return true
    end
end


function _M:get_total_count()
    local res, err = db:query("select count(user_id) as c from mg_user") 
    if err or not res or #res~=1 or not res[1].c then
        return 0
    else
        return res[1].c
    end
end
 
 
function _M:get_all(user_id, limits)
    local res, err = db:query("select * from mg_user where user_id !=? LIMIT " .. limits, {user_id})
	if not res or err or type(res) ~= "table" or #res <= 0 then
		return {}
	else
		return res
	end
end


return _M
