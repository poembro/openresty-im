--[[--
- @Copyright (C), 2016-12-01 sixiong.
- @Name utils.lua
- @Author sixiong
- @Version 1.0
- @Date: 2016年12月11日下午22:06:41
- @Description 常用函数库
- @Class
- @Function List
- @History <author> <time> <version > <desc>
    sixiong 2016年12月11日下午22:06:41  1.0  第一次建立该文件
--]] 
  
local pairs = pairs
local type = type
local mrandom = math.random
local mmodf = math.modf
local sgsub = ngx.re.gsub
local tinsert = table.insert 
 
local ngx_quote_sql_str = ngx.quote_sql_str
 
local encode_base64 = ngx.encode_base64;
local decode_base64 = ngx.decode_base64;

local _M = {}

function _M.clear_slash(s)
    s, _ = sgsub(s, "(/+)", "/")
    return s
end


function _M.is_table_empty(t)
    if t == nil or _G.next(t) == nil then
        return true
    else
        return false
    end
end

function _M.table_is_array(t)
    if type(t) ~= "table" then return false end
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then return false end
    end
    return true
end

function _M.mixin(a, b)
    if a and b then
        for k, v in pairs(b) do
            a[k] = b[k]
        end
    end
    return a
end

function _M.random()
    return mrandom(0, 1000)
end


function _M.total_page(total_count, page_size)
    local total_page = 0
    if total_count % page_size == 0 then
        total_page = total_count / page_size
    else
        local tmp, _ = mmodf(total_count/page_size)
        total_page = tmp + 1
    end

    return total_page
end


function _M.secure_str(str)
    return ngx_quote_sql_str(str)
end


function _M.string_split(str, delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end
    
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        tinsert(result, match)
    end
    return result
end

return _M
