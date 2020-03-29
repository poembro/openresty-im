return {
    -- 白名单配置：不需要登录即可访问；除非要二次开发，否则不应更改
    whitelist = { 
        "^/auth/login$", -- login page
        "^/auth/register$", -- sign up page
        "^/auth/test$", 
        "^/about$", -- about page
        "^/error/$" -- error page
    },
    -- 静态模板配置，保持默认不修改即可
    view_config = {
        engine = "tmpl",
        ext = "html",
        views = "/data/web/openresty-im/web/app/views/"
    },
    -- 分页时每页条数配置
    page_config = {
        index_topic_page_size = 10, -- 首页每页文章数
        topic_comment_page_size = 20, -- 文章详情页每页评论数
        notification_page_size = 10, -- 通知每页个数
    },
 
    refresh_cookie = true,

    url  = "ws://47.107.163.111:80/sub",
    -- mysql配置
    mysql = { -- mysql config
        timeout = 5000, 
        connect_config = {
            host = "127.0.0.1",
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
        dir = "/data/web/openresty-im/web/app/static/avatar/", -- 文件目录，修改此值时须同时修改nginx配置文件中的$static_files_path值
        chunk_size = 8096, 
        recieve_timeout = 20000,
        url = "/static/avatar/"
    }
 
}
