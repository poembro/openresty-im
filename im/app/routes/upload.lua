local pairs = pairs
local ipairs = ipairs
local utils = require("app.libs.utils")
local lor = require("lor.index")
local user_model = require("app.model.user") 
local upload_router = lor:Router()
local upload_url = require("app.config.config").upload_config.url

local  magick = require("magick.init")  --图片裁剪
local  upload_dir_thumb_img = require("app.config.config").upload_config.dir
	
upload_router:post("/face", function(req, res, next)
    local file = req.file or {}
    local userid = req.me.userid; 
    
    if file.success and file.filename then 
        user_model:update_face(userid, file.filename)

        ngx.log(ngx.ERR, "用户:", userid, " 上传头像:", file.filename, " 成功")
        res:json({
            success = true, 
            originFilename = file.origin_filename,
            filename = upload_url..file.filename
        })
    else
        ngx.log(ngx.ERR, "用户:", userid, " 上传头像失败:", file.msg)
        res:json({
            success = false, 
            msg = file.msg
        })
    end
end)



upload_router:post("/file", function(req, res, next)
    local file = req.file or {}
    local userid = req.me.userid;
 
    local thumb_imgname = upload_dir_thumb_img .. "100x100_" .. file.filename 
    magick.thumb(file.path, "100x100", thumb_imgname)
 
    if file.success and file.filename then 
        ngx.log(ngx.ERR, "用户:", userid, " 上传文件:", file.filename, " 成功")
        res:json({
            success = true, 
            originFilename = upload_dir_thumb_img .. file.origin_filename,
            filename = upload_url.. "100x100_" .. file.filename
        })
    else
        ngx.log(ngx.ERR, "用户:", userid, " 上传文件失败:", file.msg)
        res:json({
            success = false, 
            msg = file.msg
        })
    end
end)


return upload_router
