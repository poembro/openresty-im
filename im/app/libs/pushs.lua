-- cjson 模块
local cjson = require "cjson"

local _M = {_VERSION = '0.01'}
-- 频道数量
_M.channels_len = 0
-- 当前读位置
_M.idx_read = 0
-- 共享内存
_M.store = nil

-- 配置信息
_M.config = {
    -- 推送间隔，1s
    ['push_interval'] = 1,
    -- 消息队列最大长度
    ['msglist_len'] = 100,
    -- 消息生存周期
    ['msg_lefttime'] = 3,
    -- 频道空闲超时
    ['channel_timeout'] = 30,
    -- 推送空闲超时，在改时间段内无消息则关闭当前推送连接
    ['push_free_timeout'] = 10,
    -- 共享内存名
    ['store_name'] = 'push',
    -- 频道号
    ['channels'] = {1000, 2000}, 
    --当前读取位置
    ['idx_read'] = 0,
}

--[[
-- 设置
--]]
_M.opt = function(self, k, v)
    local t = type(k)
    if t == 'table' then
        for key, val in pairs(k) do
            self.config[key] = val
        end
    end

    if t == 'string' then
        self.config[k] = v
    end

    self.idx_read = self.config['idx_read']
    self.channels_len = table.maxn(self.config['channels'])
    self.store = ngx.shared[self.config['store_name']]
end


--[[
-- 向频道写入消息
-- @param ngx.shared.dict, 共享内存
-- @param string channel_id,可用ngx.crc32_long生成
-- @param int channel_timeout, 频道空闲超时时间
-- @param string msg,消息内容 必须为字符串
-- @param int msg_lefttime， 消息生存周期
-- @param int msglist_len, 消息队列长度
-- @return boolean
--]]
local function _write(store, channel_id, channel_timeout, msg, msg_lefttime, msglist_len)  
    local idx, ok, err
    -- 消息当前读取位置计数器+1
    idx, err = store:incr(channel_id, 1)
    -- 如果异常，则新建频道
    if err then
        ok, err = store:set(channel_id, 1, channel_timeout) 
        if err then  
           return 0
        end
        idx = 1
    else
        ok, err =  store:replace(channel_id, idx, channel_timeout)
        if err then 
            return 0 
        end
    end

    -- 写入消息 
    ok, err = store:set('m' .. channel_id .. idx, msg,  msg_lefttime) 
    if err then 
        return 0 
    end
    --ngx.log(ngx.ERR, 'set(m' .. channel_id .. idx, '----->' , msg, '<------',  msg_lefttime..');');
    -- 清除队列之前的旧消息
    if idx > msglist_len then
        store:delete('m' .. channel_id .. (idx - msglist_len))
    end
 
    return idx
end

local resty_lock = require "resty.lock"

--[[
-- 向频道写入消息
-- @param ngx.shared.dict, 共享内存
-- @param string channel_id,可用ngx.crc32_long生成
-- @param int channel_timeout, 频道空闲超时时间
-- @param string msg,消息内容 必须为字符串
-- @param int msg_lefttime， 消息生存周期
-- @param int msglist_len, 消息队列长度
-- @return boolean
--]]
local function _write2(store, channel_id, channel_timeout, msg, msg_lefttime, msglist_len) 
    local lock = resty_lock:new("channels", {exptime=5})
    local elapsed, err = lock:lock("lock_123456")
    if not elapsed then return 0  end

    local idx, ok, err
    -- 消息当前读取位置计数器+1
    idx, err = store:incr(channel_id, 1)  

    -- 如果异常，则新建频道
    if err then
        ok, err = store:set(channel_id, 1, channel_timeout) 
        if err then 
           lock:unlock();
           return 0
        end
        idx = 1
    else
        store:replace(channel_id, idx, channel_timeout)
    end

    -- 写入消息 
    ok, err = store:set('m' .. channel_id .. idx, msg,  msg_lefttime)

    if err then
        lock:unlock();
        return 0 
    end
    --ngx.log(ngx.ERR, 'set(m' .. channel_id .. idx, '----->' , msg, '<------',  msg_lefttime..');');
    -- 清除队列之前的旧消息
    if idx > msglist_len then
        store:delete('m' .. channel_id .. (idx - msglist_len))
    end

    lock:unlock();
    return idx
end

--[[
-- 发送消息到指定频道
-- @param string  msg，消息
-- @return  idx  当前写入最新id
--]]
_M.send = function(self, msg)
    local channels = self.config['channels'];
    local channels_length = table.maxn(channels)
    local idx = 0
    for i = 1, channels_length do
        idx = _write(self.store, channels[i], self.config['channel_timeout'], msg, 
                        self.config['msg_lefttime'], self.config['msglist_len'])
    end
    return idx
end

--[[
-- 从频道读取消息 
-- @param int channel_id, 必须为整形，可用ngx.crc32_long生成
-- @param int msglist_len，消息队列长度 暂未使用
-- @param int idx_read,  当前读取位置
-- @return  idx_read, idx_msg, string msg, 消息  
--]]
local _read = function (store, channel_id, msglist_len, idx_read) 
    local msg = nil; 
    local idx_read = tonumber(idx_read)  
    local idx_new_msg, _ = store:get(channel_id)   
    idx_new_msg = tonumber(idx_new_msg) or 0
 
	if (idx_new_msg <= 0)  or (idx_read > idx_new_msg) then 
	    idx_read = 0  --频道超时 or 客户端偏移过大
	end 

    if idx_new_msg - idx_read > 0 then 
        idx_read = idx_new_msg - 1;   --中途插入进来的会员 
    end

    --ngx.log(ngx.ERR,  idx_read, '------> ', idx_new_msg) 
    if idx_read < idx_new_msg  then
        idx_read = idx_read + 1
        msg, _ = store:get('m' .. channel_id .. idx_read) 

        --ngx.log(ngx.ERR, 'get(m' .. channel_id .. idx_read..')', msg, '消息最新位置-> ', idx_new_msg) 
    end
 
    return idx_read, idx_new_msg, msg 
end

--[[
-- 推送消息
-- @param callback wrapper, 消息包装回调函数
--]]
_M.push = function(self, wrapper)
    local channels = self.config['channels']  --这里必须用新变量 否则有缓存
    local channels_length = table.maxn(channels) 
    local array_push = table.insert
    local flag_work = true
    local flag_read = true
    local idx_read = self.config['idx_read']
    local idx_new_msg
    local msg
    local err,i 
    local time_last_msg = ngx.time()
    local res = {}  --返回结果集 
    
    while flag_work do
        
        for i = 1, channels_length do
            flag_read = true
            while flag_read do
                idx_read, idx_new_msg, msg = _read(self.store, channels[i],
                    self.config['msglist_len'], idx_read)
                   			
                if msg then
    	            time_last_msg = ngx.time(); 
    	            msg = cjson.decode(msg);  --正式线上,可以在return后包装这些信息
    	            msg['idx_read'] = idx_read; 
    	            msg['idx_new_msg'] = idx_new_msg;  
    	            msg['response_timeline'] = time_last_msg; 
    	            msg['status'] = 1 
    	            array_push(res, msg); 
                end
                    
                if idx_read >= idx_new_msg then  
                        --1.第一次位置都相等或者没有最新消息,退出此while...  
                        --2.消息太快某客户读的位置 与最新位置差距过大，继续读取...
                    flag_read = false
                end 
            end  --end while
        end --end for

        if #res > 0 then
            flag_work = false
            time_last_msg = ngx.time();
            wrapper(res);
        end
 
        if ngx.time() - time_last_msg  >= self.config['push_free_timeout'] then
            flag_work = false
        end

        ngx.sleep(self.config['push_interval'])  
    end 
    
    return idx_read   --即便是超时也返回当前最新的偏移
end



--[[
-- jsonp格式化
-- @param string  json   数据 
-- @param string  cb，   函数名
-- @return  string  cb(json)  or  json
--]]
_M.jsonp = function(self, data, cb)
    if cb then
        return cb .. "(" .. cjson.encode(data)  .. ");"
    else
        return cjson.encode(data)
    end
end
 
--[[
-- 公开成员
--]]
_M.new = function(self)
    return setmetatable({}, { __index = _M })
end

return _M
