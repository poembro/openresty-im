local xpcall = xpcall
local debug = debug

local main = require("comet.app.websocket") 
 
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
 

local ok, e
ok = xpcall(function()
    main:run()
end, function(msg)
    e = debug.traceback()
    dump(msg) 
end)

if not ok or e then
    ngx.log(ngx.ERR, "--> error:", e)
    return false
end

