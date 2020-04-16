# OpenResty IM  
一个运行在[OpenResty](http://openresty.org)上的web聊天软件。

---

## 特点
- 简洁
- 高性能
- 支持心跳来维持在线 
- 基于 redis 发布订阅做推送
- 采用 TLV 协议格式，保持与[goim](https://github.com/Terry-Mao/goim)一致  
- 存储采用 MySQL，Redis 
- c10K以内的并发连接完全够用, 如需扩展，后端可直接切换 goim  
- wap版ui推送界面 

---

## 描述
- 适用于中小型项目，新项目如果直接上goim这种推送，维护成本太高，短时间内很难驾驭，于是折中一下写了这个demo。既能应对当前开发工作量，也确保了后期扩展无缝切换后端推送服务 

---

## 案例


![im](/web/app/static/avatar/im.png)

---

## 安装
``` 
1. 安装mysql并导入handan.sql   
2. 安装redis 
3. 修改 config.lua 配置文件 

[root@iZ~]#wget https://openresty.org/download/openresty-1.11.2.3.tar.gz
[root@iZ~]#tar xvf openresty-1.11.2.3.tar.gz
[root@iZ~]#cd openresty-1.11.2.3
./configure --with-luajit && make && make install
[root@iZ~]#cd /data/web
[root@iZ~]#git clone git@github.com:poembro/openresty-im.git 
[root@iZ~]#/usr/local/openresty/sbin/nginx -c /data/web/nginx.conf
```


## 协议格式  
#### 二进制，请求和返回协议一致 
| 参数名     | 必选  | 类型 | 说明       |
| :-----     | :---  | :--- | :---       |
| package length        | true  | int32 bigendian | 包长度 |
| header Length         | true  | int16 bigendian    | 包头长度 |
| ver        | true  | int16 bigendian    | 协议版本 |
| operation          | true | int32 bigendian | 协议指令 |
| seq         | true | int32 bigendian | 序列号 |
| body         | false | binary | $(package lenth) - $(header length) |

![protocol](/web/app/static/avatar/protocol.png)

#### 协议指令
| 指令     | 说明  | 
| :-----     | :---  |
| 2 | 客户端请求心跳 |
| 3 | 服务端心跳答复 |
| 5 | 下行消息 |
| 7 | auth认证 |
| 8 | auth认证返回 |


---


## 切换至goim后端 (暂未使用)
``` 
1.长连接server地址，修改为goim comet服务的 ip、 port
2.将POST过来的消息 用 protobuf 序列化 后写入kafka

安装参考 https://zhuanlan.zhihu.com/p/26014103 
cd /data/web/openresty-im/proto
protoc -o logic-goim.pb logic-goim.proto

```


## 感谢

- 感谢毛剑大神开源这么美的代码，供大伙参考
 
 
