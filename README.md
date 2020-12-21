# OpenResty IM  
一个运行在[OpenResty](http://openresty.org)上的客服聊天软件。

---

## 特点
- 简洁  
- 高性能
- 代码完全采用ngx-lua + redis实现
- 支持心跳包,已读/未读数,历史消息同步,断线重连等
- 采用redis发布、订阅做推送
- 采用TLV协议格式，保持与B站开源项目[goim](https://github.com/Terry-Mao/goim)协议一致
- c10K以内的并发连接完全够用
---

## 描述
- 适用于中小型项目，新项目直接上goim推送，维护成本太高，短时间内很难驾驭，于是折中一下写了这个demo。既能应对当前开发工作量,也确保了后期无缝切换后端推送服务 

---

## 案例

   [体验demo](https://kefu.sgsbbs.cn/find.html)

---


## 项目目录简介
```
api:          http api服务代码 (负责组装/验证参数 跳转到聊天页面的接口,接收新消息的接口)
comet:        推送服务代码 (负责下发消息, 客户端通过http协议，将新消息POST到api服务,写入redis,再由推送服务读取redis 下发)
dist:         前端html代码
libs:         自定义的共有代码
lor:          http服务框架代码
resty:        第三方基础库代码(如 snowflake 雪花算法生成唯一id)
config:       配置
``` 

---

### 设计方案
**所有的聊天回话都是向某一个room_id中写消息**：
- 新成员进入聊天窗口，都必先有个唯一mid标识,两个成员直接相互聊天，本质上就是向两个mid拼接后的字符串(room_id)写消息；如果有多人群聊即多对多，需额外处理，并不影响该设计

**推送消息时采用读扩散**：
- 即所有消息只写1次. 所有人发送的消息时都有个room_id，服务端将消息入库到对应room_id中，并且客户端每读1条消息将会上报该消息的偏移位置

**redis采用5种不同类型的key**:
- hset(mid, key, userJson)    注:用户表  mid即唯一用户id;  key即:设备标识; userJson即用户详细 如头像 昵称等
- set(key, server_ip)         注:在线标识  心跳包维持过期时间
- hset(mid_seq, room_id, snowflake_id) 注:用户读取的偏移位置
- zadd(userlist:shop_id,time(),mid) 注:1个商户下有多个新成员,用于商户管理属于自己的用户
- zadd(room_id,snowflake_id,msg)  注:消息表
- sadd  "shoplist:" 8000       注:汇总所有商户 方便统计运营
- lpush shop_id mid            注:商户管理界面临时会话列表页面 只关心最新的消息.

---

## 安装
``` 
1. 安装redis 并启动
2. 修改 config.lua 配置文件 

[root@iZ~]#wget https://openresty.org/download/openresty-1.11.2.3.tar.gz
[root@iZ~]#tar xvf openresty-1.11.2.3.tar.gz
[root@iZ~]#cd openresty-1.11.2.3
./configure --with-luajit && make && make install
[root@iZ~]#cd /data/web
[root@iZ~]#git clone git@github.com:poembro/openresty-im.git 
[root@iZ~]#/usr/local/openresty/sbin/nginx -c /data/web/nginx.conf


项目对接：
客服人员的浏览器打开
https://kefu.sgsbbs.cn/info.html?shop_id=8000

前端网页中相应位置按钮连接改为：
https://kefu.sgsbbs.cn/open/im?shop_id=8000

注： 8000表示商户号,如果有多个商户直接递增如:8001, 前端网页连接 同样改为8001
```


---

## 协议格式  (同goim)
#### 二进制，请求和返回协议一致 
| 参数名     | 必选  | 类型 | 说明       |
| :-----     | :---  | :--- | :---       |
| package length        | true  | int32 bigendian | 包长度 |
| header Length         | true  | int16 bigendian    | 包头长度 |
| ver        | true  | int16 bigendian    | 协议版本 |
| operation          | true | int32 bigendian | 协议指令 |
| seq         | true | int32 bigendian | 序列号 |
| body         | false | binary | $(package lenth) - $(header length) |


#### 协议指令
| 指令     | 说明  | 
| :-----     | :---  |
| 2 | 客户端请求心跳 |
| 3 | 服务端心跳答复 |
| 5 | 下行消息 |
| 7 | auth认证 |
| 8 | auth认证返回 |
| 14 | 同步历史消息 |
| 15 | 同步历史消息返回 |
| 16 | 消息ack |
| 17 | 消息ack返回 |
---


## 感谢

#### 感谢openresty的开源 感谢goim的开源
 
 