local pairs = pairs
local ipairs = ipairs
local utils = require("app.libs.utils")  
local user_model = require("app.model.user") 


local lor = require("lor.index")
local imRouter = lor:Router()

imRouter:get("/room", function(req, res, next)
    local userid = req.me.userid 
    local user, err = user_model:query_by_id(userid)

    if not user or err then
       return res:json({
            success = false,
            msg = "无法查找到该用户."
        })
    end   
    
    local IMrand = math.random(1000, 9999)
    local IMtoken = utils.encrypted('1000'..'--||'.. IMrand ..'--||'.. userid, '123456789')
--ngx.log(ngx.ERR, "IMrand:", IMrand)
    res:render("im", {
         IMrand = IMrand,
         IMtoken = IMtoken,
         roomid = 1000,
         roomname = "讨论群",
         user =  (user),
         oldmessage = {}  
    })
end)



local app_libs_pushs = require("app.libs.pushs")
local app_libs_pushs_obj = app_libs_pushs:new()

--- 退出
local function exit(is_ws)
  if is_ws == nil then  
    ngx.eof();
   end
  ngx.exit(444);
end
 
 --注册abort事件处理函数
local ok, err = ngx.on_abort(exit);
if err then
   exit();
end
	

imRouter:post("/pub", function(req, res, next)
    local post_data = req.body.data 
    local post_channel_name = tonumber(req.body.roomid);
   
	local pub = app_libs_pushs_obj;
	pub:opt({
	    ['channels'] =  {post_channel_name},
	    ['push_interval'] = 0.2, -- 推送间隔，1s
	    ['msglist_len'] = 100, --消息队列只存最新100条数据
	    ['msg_lefttime'] = 4, --消息生存周期 3s
	    ['channel_timeout'] = 86400, -- 频道生存周期30s
	    ['push_free_timeout'] = 27,  -- 推送空闲超时，在该时间段内无消息则关闭当前推送连接 
	    ['store_name'] = 'channels',  -- 共享内存名
	});
 
    local res_index = pub:send(post_data or '')
    
    if tonumber(res_index) > 0 then
	    return res:json({
	        status = res_index,
	        timeline=ngx.time(),
            success = true,
            msg = "成功."
        })
	else
	    return res:json({
	        status = 0,
	        timeline= ngx.time(),
            success = false,
            msg = "成功."
        })
	end
end)



---读取存在问题,响应缓慢
imRouter:get("/sub", function(req, res, next)
    local get_channel_id = tonumber(req.query.roomid) or 0  --当前页参数
    local get_callback =  req.query.callback 
    local idx_read =  req.query.idx_read

    local sub = app_libs_pushs_obj;
    sub:opt({
	    ['channels'] =  {get_channel_id},
	    ['idx_read'] = idx_read or 0 ,   
	    ['push_interval'] = 0.2, -- 推送间隔，1s
	    ['msglist_len'] = 100, --消息队列最大长度
	    ['msg_lefttime'] = 4, -- 消息生存周期
	    ['channel_timeout'] = 86400, -- 频道生存周期
	    ['push_free_timeout'] = 27,  -- 推送空闲超时，在该时间段内无消息则关闭当前推送连接 
	    ['store_name'] = 'channels',  -- 共享内存名 
	});
	
	local wrapper = function(msg)
	    ngx.header['Content-Type'] = 'text/javascript;charset=UTF-8';
	    ngx.status = ngx.HTTP_OK;
	    ngx.say(sub:jsonp(msg, get_callback));
	   
	    ngx.flush(true) 
	    ngx.exit(ngx.HTTP_OK);
	end
	
	local idx_read = sub:push(wrapper); 
	  
	local st = {{['idx_read'] = idx_read,   ['status'] = 0, 
                ['tips'] = 'timeout',  ['timeline']= ngx.time()
               }}  
               
	res:send(sub:jsonp(st, get_callback))  
	ngx.flush(true)
end)


return imRouter