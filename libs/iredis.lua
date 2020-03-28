-- Copyright (C) 2015-2016 YuanSheng Wang, Qihoo 360 Inc.

--[[
    --使用案例
	local sredis = require "resty.iredis" 
    local redis_conn_opts = {
        timeout = 3,            -- 3s
        ip = "127.0.0.1",
        port = 6379,
        keepalive_size = 100,
        keepalive_timeout = 60000,        -- 60s
        passwd = '111111'
    }  
    local red = sredis:new(redis_conn_opts) 
    local res, err = red:set(key, val)
    if res then
        return res
    else
        log.err("failed to set: ", err)
        return nil
    end  
--]]

local redis_c = require "resty.redis"

local logger = ngx.log
local ERR = ngx.ERR
local INFO = ngx.INFO
local DEBUG = ngx.DEBUG


local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end


local _M = new_tab(0, 155)
_M._VERSION = '0.01'


local commands = {
    "append",            "auth",              "bgrewriteaof",
    "bgsave",            "bitcount",          "bitop",
    "blpop",             "brpop",
    "brpoplpush",        "client",            "config",
    "dbsize",
    "debug",             "decr",              "decrby",
    "del",               "discard",           "dump",
    "echo",
    "eval",              "exec",              "exists",
    "expire",            "expireat",          "flushall",
    "flushdb",           "get",               "getbit",
    "getrange",          "getset",            "hdel",
    "hexists",           "hget",              "hgetall",
    "hincrby",           "hincrbyfloat",      "hkeys",
    "hlen",
    "hmget",              "hmset",      "hscan",
    "hset",
    "hsetnx",            "hvals",             "incr",
    "incrby",            "incrbyfloat",       "info",
    "keys",
    "lastsave",          "lindex",            "linsert",
    "llen",              "lpop",              "lpush",
    "lpushx",            "lrange",            "lrem",
    "lset",              "ltrim",             "mget",
    "migrate",
    "monitor",           "move",              "mset",
    "msetnx",            "multi",             "object",
    "persist",           "pexpire",           "pexpireat",
    "ping",              "psetex",            "psubscribe",
    "pttl",
    "publish",      --[[ "punsubscribe", ]]   "pubsub",
    "quit",
    "randomkey",         "rename",            "renamenx",
    "restore",
    "rpop",              "rpoplpush",         "rpush",
    "rpushx",            "sadd",              "save",
    "scan",              "scard",             "script",
    "sdiff",             "sdiffstore",
    "select",            "set",               "setbit",
    "setex",             "setnx",             "setrange",
    "shutdown",          "sinter",            "sinterstore",
    "sismember",         "slaveof",           "slowlog",
    "smembers",          "smove",             "sort",
    "spop",              "srandmember",       "srem",
    "sscan",
    "strlen",       --[[ "subscribe",  ]]     "sunion",
    "sunionstore",       "sync",              "time",
    "ttl",
    "type",         --[[ "unsubscribe", ]]    "unwatch",
    "watch",             "zadd",              "zcard",
    "zcount",            "zincrby",           "zinterstore",
    "zrange",            "zrangebyscore",     "zrank",
    "zrem",              "zremrangebyrank",   "zremrangebyscore",
    "zrevrange",         "zrevrangebyscore",  "zrevrank",
    "zscan",
    "zscore",            "zunionstore",       "evalsha"
}


local mt = { __index = _M }


local function is_redis_null( res )
    if type(res) == "table" then
        for k,v in pairs(res) do
            if v ~= ngx.null then
                return false
            end
        end
        return true
    elseif res == ngx.null then
        return true
    elseif res == nil then
        return true
    end

    return false
end


local function do_command(self, cmd, ... )
    if self._reqs then
        table.insert(self._reqs, {cmd, ...})
        return
    end

    local redis, err = redis_c:new()
    if not redis then
        return nil, err
    end

    local ok, err = self:connect_mod(redis)
    if not ok or err then
        return nil, err
    end

    -- auth
    if self.passwd and self.passwd ~= '' then
        local count, err = redis:get_reused_times()
        if 0 == count then
            ok, err = redis:auth(self.passwd)
            if not ok then
                return nil, err
            end
        elseif err then
            return nil, err
        end
        -- logger(DEBUG, count)
    end

    local fun = redis[cmd]
    local result, err = fun(redis, ...)
    if not result or err then
        return nil, err
    end

    if is_redis_null(result) then
        result = nil
    end

    self:set_keepalive_mod(redis)

    return result, err
end


for i = 1, #commands do
    local cmd = commands[i]
    _M[cmd] =
            function (self, ...)
                return do_command(self, cmd, ...)
            end
end


function _M.connect_mod( self, redis )
    redis:set_timeout(self.timeout)
    return redis:connect(self.ip, self.port)
end


function _M.set_keepalive_mod( self, redis )
    if not redis then 
        ngx.log(ngx.ERR, "===redis  句柄失效==>>")
        return
    end
    return redis:set_keepalive(self.keepalive_timeout, self.keepalive_size)
end


function _M.init_pipeline( self )
    self._reqs = {}
end


function _M.commit_pipeline( self )
    local reqs = self._reqs

    if nil == reqs or 0 == #reqs then
        return {}, "no pipeline"
    else
        self._reqs = nil
    end

    local redis, err = redis_c:new()
    if not redis then
        return nil, err
    end

    local ok, err = self:connect_mod(redis)
    if not ok then
        return {}, err
    end

    redis:init_pipeline()
    for _, vals in ipairs(reqs) do
        local fun = redis[vals[1]]
        table.remove(vals , 1)

        fun(redis, unpack(vals))
    end

    local results, err = redis:commit_pipeline()
    if not results or err then
        return {}, err
    end

    if is_redis_null(results) then
        results = {}
        ngx.log(ngx.INFO, "is null")
    end
    -- table.remove (results , 1)

    self:set_keepalive_mod(redis)

    for i,value in ipairs(results) do
        if is_redis_null(value) then
            results[i] = nil
        end
    end

    return results, err
end
 

function _M.subscribe( self, channel )
    local redis, err = redis_c:new()
    if not redis then
        return nil, err
    end

    local ok, err = self:connect_mod(redis)
    if not ok or err then
        return nil, err
    end

    local res, err = redis:subscribe(channel)
    if not res then
        return nil, err
    end

    local function do_read_func ( do_read )
        if do_read == nil or do_read == true then
            res, err = redis:read_reply()
            if not res then
                return nil, err
            end
            return res
        end

        if redis then
            redis:unsubscribe(channel)
            self.set_keepalive_mod(redis)
        else
            ngx.log(ngx.ERR, "===redis  句柄失效==>>")
        end
        return 
    end
    
    return do_read_func
end


function _M.new(self, opts)
    opts = opts or {}
    local timeout = (opts.timeout and opts.timeout * 1000) or 1000
    local db_index= opts.db_index or 0
    local ip      = opts.ip or "127.0.0.1"
    local port    = opts.port or 6379
    local keepalive_size    = opts.keepalive_size or 1000
    local keepalive_timeout = opts.keepalive_timeout or 60000
    local passwd = opts.passwd or ""

    return setmetatable({
            timeout = timeout,
            db_index = db_index,
            ip       = ip,
            port     = port,
            keepalive_size = keepalive_size,
            keepalive_timeout = keepalive_timeout,
            passwd = passwd
            }, mt)
end


return _M