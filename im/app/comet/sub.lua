local obj = require('app.libs.pushs');  --local obj =  dofile("/data/cluster/web/src/yaf/comet/push.lua"); 
local function exit(is_ws)
    -- if is_ws == nil then ngx.eof() end 
      ngx.flush(true);
      ngx.exit(444);
end

local ok, err = ngx.on_abort(exit)
if err then 
    return exit(); 
end

--获取URL参数
local _GET = ngx.req.get_uri_args();
local channel_id = _GET['roomid'] or 1000; 
local channel_name = tonumber(channel_id);  

local sub = obj:new();
sub:opt({
    ['channels'] =  {channel_name},
    ['idx_read'] = _GET['idx_read'] or 0 ,   
    ['push_interval'] = 0.2, -- 推送间隔，1s
    ['msglist_len'] = 100, --消息队列最大长度
    ['msg_lefttime'] = 10, -- 消息生存周期
    ['channel_timeout'] = 300, -- 频道生存周期
    ['push_free_timeout'] = 27,  -- 推送空闲超时，在该时间段内无消息则关闭当前推送连接 
    ['store_name'] = 'channels',  -- 共享内存名 
});

local wrapper = function(msg)
    ngx.header['Content-Type'] = 'text/javascript;charset=UTF-8';
    ngx.status = ngx.HTTP_OK;
    ngx.say(sub:jsonp(msg, _GET['callback']));
    ngx.exit(ngx.HTTP_OK);
    exit();
end

sub:push(wrapper);
wrapper(sub:jsonp({['status'] = 0, ['tips'] = 'timeout', ['timeline']= ngx.time()}));
