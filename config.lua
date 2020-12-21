return {
    -- 白名单配置：不需要登录即可访问；除非要二次开发，否则不应更改
    whitelist = { 
        "^/auth/login$", -- login page
        "^/auth/register$", -- sign up page
        "^/index$", 
        "^/open",
        "^/upload/file$",
        "^/about$", -- about page
        "^/error/$" -- error page
    },
    -- 静态模板配置，保持默认不修改即可
    view_config = {
        engine = "tmpl",
        ext = "html",
        views = "/data/web/openresty-im/web/app/views/"
    },
    default = {
        redirect301 = "https://kefu.sgsbbs.cn/im.html?", -- 默认跳回到商户去的网页地址
        shop_id = 8000,  -- 默认商户号 
        face = "https://kefu.sgsbbs.cn/img/21.png", --默认用户头像 
        shop_face = "https://kefu.sgsbbs.cn/img/20.png", --默认商户头像 
        suburl = "wss://kefu.sgsbbs.cn:443/sub",  --默认订阅地址
        pushurl = "https://kefu.sgsbbs.cn/open/push", --默认发送消息地址
        notic = [[curl 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=9b33a9b8-4e10-43f2-ad13-xxxxxx' -H 'Content-Type: application/json' -d '{ "msgtype": "text","text": {"content": "有新用户过来咨询 %s "}}']]
    },
    
    refresh_cookie = true,
    
    -- mysql配置
    mysql = { -- mysql config
        timeout = 5000, 
        connect_config = {
            host = "192.168.3.111",
            port = 3306,
            database = "handan",
            user = "root",
            password = "123456",
            max_packet_size = 1024 * 1024
        }, 
        pool_config = {
            max_idle_timeout = 20000, -- 20s
            pool_size = 50 -- connection pool size
        },
        desc="mysql configuration" 
    },
    redis = {
        timeout = 3,            -- 3s
        ip = "127.0.0.1",
        port = 6379,
        keepalive_size = 100,
        keepalive_timeout = 60000,        -- 60s
        passwd = ''
    },
     -- 上传文件配置，如上传的头像、文章中的图片等
    upload_config = {
        dir = "/data/web/openresty-im/dist/upload/", -- 文件目录，修改此值时须同时修改nginx配置文件中的$static_files_path值
        chunk_size = 8096, 
        recieve_timeout = 20000,
        url = "/upload/"
    },
     -- 分页时每页条数配置
     page_config = {
        index_topic_page_size = 10, -- 首页每页文章数
        topic_comment_page_size = 20, -- 文章详情页每页评论数
        notification_page_size = 10, -- 通知每页个数
    },
}
