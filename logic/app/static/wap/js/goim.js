(function(win){
    var _ = {} 
    _.init = function(option) {
        /*var option = {
            url : "ws://192.168.3.222:3102/sub", 
            mid: '663291537152950273',
            room_id:'live://1000',
            platform:'web',
            accepts:'[1000,1001,1002]',
            key:'53aad8dba5d8025225863f81b17951b5', 
        }*/ 
        _.config.init() //必须最先执行
        _.face.init()  //工具处理 
        _.comet.init()
        _.websocket.init() 
    }
    
    _.config = {
        options : {
            url : "ws://192.168.3.222:80/sub", 
            mid: '663291537152950273',
            room_id:'live://1000',
            platform:'web',
            accepts:'[1000,1001,1002]',
            key:'j', 
        },
        init:function (){
            var self = this 
            self.send() 
            self.handleTitle(self.options.room_name)
            self.handleHref(self.options.mid) 
        },
        send : function() { //获取配置 
            var myself = this 
            var getQueryString = function (name){
                var reg = new RegExp("(^|&)"+ name +"=([^&]*)(&|$)");
                var r = window.location.search.substr(1).match(reg);
                if(r!=null)return  unescape(r[2]); return null;
            }
            var group_id = getQueryString("group_id");
            
            $.ajax({
                type : "POST",
                url :"/push/group",
                global: true, //希望产生全局的事件
                data : {group_id:group_id},
                timeout : 27000,
                cache:false,
                async: false, //是否异步
                contentType:'application/x-www-form-urlencoded;charset=utf-8',
                dataType:"json", // 数据格式指定为jsonp 
                //jsonp:"callback", //传递给请求处理程序或页面的，用以获得jsonp回调函数名的参数名默认就是callback
                //jsonpCallback:"getName",   // 指定回调方法
                beforeSend:function(){ 
                    //_.alert('连接中.../(ㄒoㄒ)/~~')
                },
                success:function(data){ 
                    console.log(data)
                    if (! data.success) {
                        return _.alert('连接失败/(ㄒoㄒ)/~~')
                    }
                    
                    myself.options = data.data
                    return 
                },
                error:function (res, status, errors){
                    console.log(errors)
                    return _.alert('连接失败/(ㄒoㄒ)/~~')
                },
                complete:function(){ 
                    //$("#doconfig").click();
                    return 
                }
            })
        },
        handleTitle : function(title) {
            $("#top_title").html(title) 
        },
        handleHref : function(id) {
            $("#top_href").attr("href", "/push/info?roomid=" + id) 
        }
    }

    _.comet = { 
        init:function (){
            var self = this
            $('#console_box_right').click(function(){
                self.send(null)
                $('#face_box').addClass("hide")
            })
            return true
        }, 
        send : function(msgtype) { //发送消息 
            var console_box_input = $('#console_box_input')
            var msg = console_box_input.html() //拿到输入框内容  
            var data = {}  
            data["type"]  = 'text' 
            data["msg"]  = msg 
            data["roomid"]  = _.config.options.room_id
            if (msgtype && msgtype.length > 5) {
                data["type"]  = 'image'  
                data["msg"]  = msgtype 
            }
            if (!data["msg"] || $.trim(data["msg"]) == "" || (data["msg"].length < 1 ) ) { 
                _.alert('请输入内容再发送')
                return false 
            }
            
            $.ajax({
                type : "POST",
                url :"/push/main",
                global: true, //希望产生全局的事件
                data : data,
                timeout : 27000,
                cache:false,
                async: true, //是否异步
                contentType:'application/x-www-form-urlencoded;charset=utf-8',
                dataType:"json", // 数据格式指定为jsonp 
                //jsonp:"callback", //传递给请求处理程序或页面的，用以获得jsonp回调函数名的参数名默认就是callback
                //jsonpCallback:"getName",   // 指定回调方法
                beforeSend:function(){
                    //return console.log('发送中...')
                },
                success:function(data){ 
                    if (data.status < 1) {
                        return _.alert('消息发送失败/(ㄒoㄒ)/~~')
                    }
                    return 
                },
                error:function (res, status, errors){
                    console.log('消息发送失败/(ㄒoㄒ)/~~')
                    return _.alert('消息发送失败/(ㄒoㄒ)/~~')
                },
                complete:function(){
                    //console.log('发送成功')
                    return 
                }
            })
            console_box_input.html("") 
            return true
        }
    }
 
    const rawHeaderLen = 16
    const packetOffset = 0
    const headerOffset = 4
    const verOffset = 6
    const opOffset = 8
    const seqOffset = 12 
    _.websocket = {
        ws : null,
        textDecoder : null,
        textEncoder : null,
        heartbeatInterval : null,  //定时器句柄 
        init : function(){
            var self = this 
        
            self.textDecoder = new TextDecoder()
            self.textEncoder = new TextEncoder()

            var MAX_CONNECT_TIMES = 10 //最大重连次数
            var DELAY = 15000          //每隔30秒连一次 
            self.createConnect(MAX_CONNECT_TIMES, DELAY)
        }, 
        createConnect : function (max, delay) {
            var self = this
            if (max === 0) {
                return
            }
            var ws = new WebSocket(_.config.options.url) 
            ws.binaryType = 'arraybuffer'
            ws.onopen = function() {
                self.auth(ws)
            }
            ws.onmessage = function(evt) {
                var data = evt.data
                var dataView = new DataView(data, 0)
                var packetLen = dataView.getInt32(packetOffset)
                var headerLen = dataView.getInt16(headerOffset)
                var ver = dataView.getInt16(verOffset)
                var op = dataView.getInt32(opOffset)
                var seq = dataView.getInt32(seqOffset)

                //console.log("receiveHeader: packetLen=" + packetLen, "headerLen=" + headerLen, "ver=" + ver, "op=" + op, "seq=" + seq)

                switch(op) {
                    case 8:
                        // auth reply ok 
                        self.heartbeat(ws)

                        self.heartbeatInterval = setInterval(function(){
                            self.heartbeat(ws)
                        }, 30 * 1000)
                        break
                    case 3:
                        // receive a heartbeat from server
                        //console.log("receive: heartbeat")
                        //appendMsg("receive: heartbeat reply")
                        break
                    case 9:
                        // batch message
                        var offset = rawHeaderLen 
                        for (; offset<data.byteLength; offset+=packetLen) {
                            // parse
                            var packetLen = dataView.getInt32(offset)
                            var headerLen = dataView.getInt16(offset+headerOffset)
                            var ver = dataView.getInt16(offset+verOffset)
                            var op = dataView.getInt32(offset+opOffset)
                            var seq = dataView.getInt32(offset+seqOffset)
                            var msgBody = self.textDecoder.decode(data.slice(offset+headerLen, offset+packetLen))
                            // callback
                             
                            console.log("receive1: ver=" + ver + " op=" + op + " seq=" + seq + " message=" + msgBody)

                            self.messageReceived(ver, msgBody) 
                        }
                        break
                    default:
                        var msgBody = self.textDecoder.decode(data.slice(headerLen, packetLen))
                        //console.log("receive2: ver=" + ver + " op=" + op + " seq=" + seq + " message=" + msgBody)
                        self.messageReceived(ver, msgBody)
                        break
                }
            }

            ws.onclose = function() {
                if (self.heartbeatInterval) clearInterval(self.heartbeatInterval);
                setTimeout(reConnect, delay)
                _.alert("连接异常...")
            }
            function reConnect() {
                self.createConnect(--max, delay * 2)
            } 
        },
        heartbeat : function (ws) {
            var headerBuf = new ArrayBuffer(rawHeaderLen) //分配16个固定元素大小
            var headerView = new DataView(headerBuf, 0) //读写时手动设定字节序的类型
            headerView.setInt32(packetOffset, rawHeaderLen) //写入从内存的第0个字节序开始  值为16
            headerView.setInt16(headerOffset, rawHeaderLen) //写入从内存的第4个字节序开始  值为16
            headerView.setInt16(verOffset, 1)  //写入从内存的6第个字节序开始，值为1     省去的第三个参数: true为小端字节序，false为大端字节序 不填为大端字节序
            headerView.setInt32(opOffset, 2)   //写入从内存的8第个字节序开始，值为2
            headerView.setInt32(seqOffset, 1)  //写入从内存的12第个字节序开始，值为1 
            ws.send(headerBuf)
            //console.log("send: heartbeat")
            //appendMsg("send: heartbeat")
        },
        auth: function (ws) {
            var self = this
            //协议格式对应 /api/comet/grpc/protocol
            //var token = '{"mid":123, "room_id":"live://1000", "platform":"web", "accepts":[1000,1001,1002]}'
            var token = '{"mid":"' + _.config.options.mid + '", "room_id":"' + _.config.options.room_id + '", "platform":"' + _.config.options.platform + '", "accepts":' + _.config.options.accepts + ',"key":"' + _.config.options.key + '"}'
            var headerBuf = new ArrayBuffer(rawHeaderLen) 
            var headerView = new DataView(headerBuf, 0)
            var bodyBuf = self.textEncoder.encode(token) //接收一个String类型的参数返回一个Unit8Array 1个字节
            headerView.setInt32(packetOffset, rawHeaderLen + bodyBuf.byteLength) //包长度  写入从内存的第0个字节序开始  值为16 + token长度
            headerView.setInt16(headerOffset, rawHeaderLen) //写入从内存的第4个字节序开始  值为16
            headerView.setInt16(verOffset, 1) //版本号为1
            headerView.setInt32(opOffset, 7)  //写入从内存的8第个字节序开始，值为7 标识auth
            headerView.setInt32(seqOffset, 1) //从内存的12个字节序开始· 值为1   序列号（服务端返回和客户端发送一一对应）
            ws.send(self.mergeArrayBuffer(headerBuf, bodyBuf))

            //console.log("send: auth token: " + token)
        }, 
        messageReceived :  function (ver, body) { 
            //console.log("messageReceived:", "ver=" + ver, "body=" + body)  
            var show = JSON.parse(body) 
            //消息类型处理
            //console.log( show )  
            if (show) {
                _.render.show(show)
            }
        },
        mergeArrayBuffer : function (ab1, ab2) {
            var u81 = new Uint8Array(ab1),
                u82 = new Uint8Array(ab2),
                res = new Uint8Array(ab1.byteLength + ab2.byteLength)
            res.set(u81, 0)
            res.set(u82, ab1.byteLength)
            return res.buffer
        },
    }
    
    _.render = {
        /**
        local data = {
            me = {mid = mid, nickname=nickname, mobile = mobile, face = face}, 
            type = type,
            msg = msg,
            roomid = roomid, 
            dateline = dateline
        }
         */

	    show : function(res) { //渲染消息 
            var self = this
            var html = null  
            var msg = null
            var dateline = null
            var me = null
            var msgtype = null
            if (!res.msg) {
                return console.log("参数必须要有 msg")
            }
            if (!res.dateline) {
                return console.log("参数必须要有 dateline")
            }
            if (!res.me) {
                return  console.log("参数必须要有 me")
            }
            if (!res.type) {
                return console.log("参数必须要有 type")
            }
            msg = res.msg
            dateline = res.dateline
            msgtype = res.type
            me = res.me

            dateline = new Date(parseInt(dateline) * 1000).toLocaleString().replace(/年|月/g, "-").replace(/日/g, " ")  
            if (msg && (msg).length > 2) {
                msg = _.face.handleface( msg ) //表情过滤
            }
            
            var face = me.face ||  "/static/wap/img/portrait.jpg"
            if (me.mid == _.config.options.mid) { 
                html = self.message_me(face, me.nickname,  dateline, msg, msgtype)
            } else { 
                html = self.message(face, me.nickname,  dateline, msg, msgtype)
            }
            
            var messageList = $("#messageList")
            //messageList.append($(html).hide().fadeIn('slow')) 
            messageList.append(html) 
            //判断长度 是否需要删除 
            if (messageList.children().length > 26) {
                messageList.children().first().remove() 
            }
            _.scrollTop()
        },  
        message : function (face, nickname, time, msg, msgtype) { //别人发消息给我的模板； 
            var str = '<div class="message">  ';//4
            str += '     <img src="'+face+'" class="avatar"/>';
            str += '     <div class="content">  ';//3
            str += '        <div class="nickname"><span class="time">' + nickname + '    '+time+'</span></div> '; 
            if (msgtype == 'image'){
                str += '<div class="bubble bubble_default left transparent">  ';
                str += '<img src="'+ msg +'" class="msg-img"/>';
                str += '</div>  ';
            } else {
                str += '<div class="bubble bubble_default left">  ';
                str += '<pre>'+msg+'</pre>';
                str += '</div>  ';
            }
            str += '  </div> '; //3
            str += '</div>';//4
            return str;
        },
        message_me : function (face, nickname, time, msg, msgtype){ //我自己发消息模板； 
            var str = '<div class="message me">  ';//4
            str += ' <img src="'+face+'" class="avatar"/>  ';
            str += '<div class="content">  ';//3
            str += '<div class="nickname"><span class="time">' + time+ '    ' + nickname +'</span></div>  ';
           
            if (msgtype == 'image'){
                str += '<div class="bubble bubble_primary right transparent">  ';//2 
                str += '<img src="' + msg + '" class="msg-img"/>';
                str += '</div>  ';//2
            } else {
                str += '<div class="bubble bubble_primary right">  ';//2 
                str += '<pre>'+msg+'</pre>';
                str += '</div>  ';//2
            }
            str += '   </div>  ';//3
            str += '  </div>';//4
           return str;
        }
    }
    
    _.scrollTop = function () {
        setTimeout(function () {
            var messageList = $("#messageList")
            var num = messageList.scrollTop()
            //console.log("当前消息列表高度", num + " px")
            messageList.scrollTop(num + 10000) 
        }, 200)
    }
    
    _.alert = function(msg) {
        var domsg = $("#domsg") 
        if (domsg.length < 1) {
            domsg = document.createElement("div")
            domsg.id = "domsg"
            domsg.className = "popupWindow"
            var string = '<div class="hint"><div class="text" id="msgtext" style="padding: 20px 0;" >'+ msg +'</div>';
            string += '<div class="btnBox"><a class="btnStyle btn01" id="doconfig" style="width: 100%;" >确定</a>';
            string += '</div></div>';
            domsg.innerHTML = string           
            document.body.appendChild(domsg)
            
            $("#doconfig").click(function() {
                $("#domsg").css("display","none") 
            })
        }
        $("#domsg").css("display","block")  
        $("#msgtext").html(msg)
    }

    //检测客户端是pc端 还是移动端
    _.checkclient =  function () {
        var userAgentInfo = navigator.userAgent
        var Agents = ["Android", "iPhone","SymbianOS", "Windows Phone","iPad", "iPod"]
        var flag = true
        for (var v = 0; v < Agents.length; v++) {
            if (userAgentInfo.indexOf(Agents[v]) > 0) {
                flag = false
                break
            }
        }
        return flag
    }
    
    _.face = { 
        init : function(){
            var self = this
            self.showFace() //展示工具按钮
            self.toggleFace() //切换工具栏目 并绑定事件 
            self.clickFacePic()  //点选表情图片
            self.clickFileUpload()  //点选图片上传
        }, 
        showFace : function(){ 
            $('#console_box_center').click(function () {
                $('#face_box').toggleClass('hide')
            })
        },
        toggleFace : function() {
            $('#face_box .face_box_head li').click(function () {
                var myself = $(this)
                var i = myself.data('i') 
                $("#face_box .face_box_head li, #face_box .face_box_body div").each(function(){
                    $(this).removeClass('active') //先抹去所有的 选中状态
                })
    
                myself.addClass('active') //本次的为选中状态
                $('#face_box .face_box_body div').eq(i).addClass('active')
            })
        },
        clickFileUpload : function () {
            var inputFileDom = $('#face_box_body_pic a input')
            inputFileDom.on("change", function () {
                _.upload.on(inputFileDom) 
            })
        },
        clickFacePic : function () {
            var self = this
            $('#face_box_body_qq a').click(function () {
                self.getOneFace(this)
            })
        },
        getOneFace : function(self) {
            var myself = $(self)
            var html = '[' + myself.attr('title') + ']'
            var console_box_input = $('#console_box_input')
            console_box_input.html(console_box_input.html() + html)  
        },
        handleface : function(str) {  //表情过滤     str="[得意]ddd[gg[6 ][发呆]6]]jjjj[发呆]j"
            var newstr = str 
            var i=0;  var x=0;  var arr=[];
            var fn = function(s,y,p) {
                var a=fn.arguments,l=a.length,s=a[0],p=a[l-2];
                if(s=="["){ i+=1; if (i==1) { x=p; } }
                if(s=="]"){
                    i-=1;
                    if(i==0) {
                        arr.push(str.slice(x+1,p));
                    }
                    if (i<0) {i=0;}
                }
                return s;
            }
            str.replace(/[\[\]]/g, fn);   
            var domObj = $('#face_box_body_qq a');
        
            for (var m in arr) {
                if ((arr[m]).length < 1 || (arr[m]).length > 5){ continue;}  //不合法表情提前过滤

                domObj.each(function(index, element) {
                    var title = element.getAttribute("title"); 
                    if ( arr[m] == title ){
                        var ls = '[' + title + ']';   
                        newstr =  newstr.replace(ls,  element. innerHTML);
                        newstr = newstr.replace('id="console_box_input"',  "");//替换重要id
                    }
                })  
            }
            return newstr
        }
    }
    
    _.upload = {
        inputFileDom: null,
        on : function (dom) {
            var self = this 
            self.inputFileDom = dom
            $.ajaxFileUpload({
                url : '/upload/file',
                timeout : 27000,
                data : {},//{'path' : $(dom).attr('path'), 'crop' : '其他字段', 'compress' : '其他字段'},
                secureuri : false,
                fileElementId : $(dom),
                dataType: 'json',
                success : function(data) {  
                    if (data['success']) { //成功  
                        self.success(data) 
                    } else {  
                        self.feild(data)   //失败
                    }
                }
            })
            return false 
        }, 
        success : function(data) {   //上传成功  
            var self = this 
            _.comet.send(data['filename']) 
            $('#console_box_center').click() 

            var outerHTML = "上传图片" + self.inputFileDom[0]['outerHTML']
            $('#face_box_body_pic_a').html(outerHTML) 
             
            _.face.clickFileUpload()  //点选图片上传
        },
        feild : function(data){
            //上传失败  
            _.alert(data.msg)
            console.log(data)
        }
    }
     
    win['_'] = _ 

})(window)

