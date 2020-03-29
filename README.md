# OpenResty IM  
一个运行在[OpenResty](http://openresty.org)上的web聊天软件。

### 特点
- 简洁
- 高性能
- 支持心跳来维持在线 
- 基于 redis 发布订阅做推送
- 采用 TLV 协议格式，保持与[goim](https://github.com/Terry-Mao/goim)一致  
- 存储采用 MySQL，Redis 
- c10K以内的并发连接完全够用, 如需扩展，后端可直接切换 goim  
- wap版ui推送界面 

### 描述
- 适用于中小型项目，根据自身遇到的问题，新项目如果直接上goim这种推送维护成本太高，短时间内很难驾驭，于是折中一下写了这个demo。既能应对当前开发工作量，也确保了后期扩展无缝切换后端推送服务 

### 案例
![im](/web/app/static/avatar/im.png)

### 安装

- 首先安装OpenResty(可以按自己的需要安装)

```
    [root@iZ~]#yum install libtermcap-devel ncurses-devel libevent-devel \
       readline-devel pcre-devel openssl openssl-devel 
     
    [root@iZ~]#wget https://openresty.org/download/openresty-1.11.2.3.tar.gz
    [root@iZ~]#tar xvf openresty-1.11.2.3.tar.gz
    [root@iZ~]#cd openresty-1.11.2.3
    ./configure --with-luajit && make && make install

    
    ##为了保持与goim协议一致 增加protobuf 
    安装参考 https://zhuanlan.zhihu.com/p/26014103

    cd /data/web/openresty-im/proto
    protoc -o logic-goim.pb logic-goim.proto
    
    
```
 