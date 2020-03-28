local pwd_secret = "lua-resty-jwt"
local jwt = require "resty.jwt"

local _M = {} 
  
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

function _M:decode(jwt_token)
    if not jwt_token or jwt_token == "" then
        return false
    end

    local jwt_obj = jwt:verify(pwd_secret, jwt_token)
    -- dump( jwt_obj )
    return jwt_obj.payload
end

function _M:encode(user_id, nickname, mobile, face)
    local jwt_token = jwt:sign(
        pwd_secret,
        {
            header = {typ="JWT", alg="HS256"},
            payload = {user_id = user_id, nickname = nickname, mobile = mobile, face = face}
        }
    )
    return jwt_token
end

return _M