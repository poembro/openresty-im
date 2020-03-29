local pairs = pairs
local ipairs = ipairs
local utils = require("libs.utils")
local lor = require("lor.index")
local user_model = require("web.dao.user") 
local _M = lor:Router()
local upload_url = require("config").upload_config.url 
local upload_dir_thumb_img = require("config").upload_config.dir

_M:post("/face", function(req, res, next)
    local file = req.file or {}
    local uid = res.locals.me.user_id; 
    
    if file.success and file.filename then 
        user_model:update_face(uid, file.filename)

        ngx.log(ngx.ERR, "用户:", uid, " 上传头像:", file.filename, " 成功")
        res:json({
            success = true, 
            --originFilename = file.origin_filename,
            filename = upload_url .. file.filename
        })
    else
        ngx.log(ngx.ERR, "用户:", uid, " 上传头像失败:", file.msg)
        res:json({
            success = false, 
            msg = file.msg
        })
    end
end)

_M:post("/file", function(req, res, next)
    local file = req.file or {}
    local uid = res.locals.me.user_id;
 
    if file.success and file.filename then  
        local thumb_imgname = upload_dir_thumb_img .. "100x100_" .. file.filename 
        --magick.thumb(file.path, "100x100", thumb_imgname)

        ngx.log(ngx.ERR, "用户:", uid, " 上传文件:", file.filename, " 成功")
        res:json({
            success = true, 
            --originFilename = upload_dir_thumb_img .. file.origin_filename,
            filename = upload_url .. file.filename
        })
    else
        ngx.log(ngx.ERR, "用户:", uid, " 上传文件失败:", file.msg)
        res:json({
            success = false, 
            msg = file.msg
        })
    end
end)


return _M
