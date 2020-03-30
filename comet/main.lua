local xpcall = xpcall
local debug = debug

local main = require("comet.app.websocket") 


local ok, e
ok = xpcall(function()
    main:run()
end, function(msg)
    e = debug.traceback()
    ngx.log(ngx.ERR, "--> msg:", msg) 
end)

if not ok or e then
    ngx.log(ngx.ERR, "--> error:", e)
    return false
end

