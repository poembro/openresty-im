local pairs = pairs
local ipairs = ipairs
local lor = require("lor.index")
local _M = lor:Router()


_M:get("/", function(req, res, next)
    res:render("error", {
        errMsg = req.query.errMsg -- injected by the invoke request
    })
end)


return _M