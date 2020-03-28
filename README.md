# OpenResty IM 

一个运行在[OpenResty](http://openresty.org)上的基于[lor](https://github.com/sumory/lor)编写的web聊天软件。

- 完全基于 OpenResty
- 存储采用 MySQL，redis 
- 协议与[goim](https://github.com/Terry-Mao/goim)一致 
- c10K以内的并发连接完全够用, 如需扩展，后端可直接切换 goim  

###
![im](/logic/app/static/avatar/im.png)

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
    cd /data/web/openresty-im/proto
    protoc -o logic-goim.pb logic-goim.proto
    

```
 