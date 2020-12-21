(function(win){
    var _GET = function (name){
        var reg = new RegExp("(^|&)"+ name +"=([^&]*)(&|$)");
        var r = win.location.search.substr(1).match(reg);
        if(r!=null)return  unescape(r[2]); return null;
    }


    
    var _ = {} 
    _.init = function() {
        _.userlist.init() 
    } 
   
    _.userlist = {
        opt : {
            shop_id : 0,
        },
        init:function (){
            var self = this
            var shop_id = _GET("shop_id") || 8000
            self.opt.shop_id = shop_id 
            
            var randomNum = function (minNum,maxNum){ 
                switch(arguments.length){ 
                    case 1: 
                        return parseInt(Math.random()*minNum+1,10);  
                    case 2: 
                        return parseInt(Math.random()*(maxNum-minNum+1)+minNum,10);  
                    default: 
                        return 0;  
                }
            };

            self.send(shop_id, 0)
            setInterval(function() {
                var num = randomNum(1, 10)
                if (num % 5 == 0) {
                    self.send(shop_id, 0)
                } else {
                    self.send(shop_id, 1)
                }
            }, 5 * 1000)

            return true
        }, 
        send : function(shop_id, flag) {
            var self = this
            var url = "/open/finduserlist?shop_id=" + shop_id + "&flag=" + flag
            $.ajax({
                type : "POST",
                url : url,
                global: true, //希望产生全局的事件
                data : {shop_id:shop_id},
                timeout : 27000,
                cache:false,
                async: true, //是否异步
                contentType:'application/json',
                dataType:"json", // 数据格式指定为jsonp 
                //jsonp:"callback", //传递给请求处理程序或页面的，用以获得jsonp回调函数名的参数名默认就是callback
                //jsonpCallback:"getName",   // 指定回调方法
                beforeSend:function(){
                    //return console.log('发送中...')
                },
                success:function(data){ 
                    if (data.success) {
                        for (var i = 0; i < data.data.length; i++) { 
                            //过滤掉自己
                            self.show( data.data[i] ,flag) 
                        }
                    }
                    return 
                },
                error:function (res, status, errors){
                    console.log(res)
                    console.log(status)
                    console.log(errors)
                    console.log('消息发送失败/(ㄒoㄒ)/~~')
                    _.alert('消息发送失败/(ㄒoㄒ)/~~')
                    return
                },
                complete:function(){
                    //console.log('发送成功')
                    return 
                }
            })
            return true
        },
        show : function(m, flag) {
            var self = this
            if (m.last.length > 5) {
                m.last = JSON.parse(m.last)
                if (!m.last.id) m.last.id = 0
            }
            if (m.user.length > 5) {
                m.user = JSON.parse(m.user) 
                if (parseInt(m.user.mid) == parseInt(self.opt.shop_id)) {
                   return
                }
            }
            // 先删除旧的
            var midLi = $("#" + m.user.mid)
            if (midLi) {  midLi.remove() }
            
            var html = ' <li class="mui-table-view-cell mui-media" id="'+m.user.mid+'">'
            html += '<a href="/open/com?shop_id='+ m.user.shop_id + '&shop_name='+m.user.shop_name+'&mid='+m.user.mid+'&nickname='+m.user.nickname+'&seq='+ m.last.id +'">'
            html += '<img class="mui-media-object mui-pull-left" src="'+m.user.face+'" />'
            html += '<div class="mui-media-body">'
            if (m.online) {
                html += '<span style="color:red;">在线</span>'
            } else {
                html += '<span>离线</span>'
            }
            html += '   ' + decodeURI(m.user.nickname)
            html += '        <span class="time">'+ self.format( m.last.dateline) +  '</span>'
            if (m.last && m.last.msg) {              
               html += '    <p class="mui-ellipsis">'+ m.last.msg +'.</p>'
            } else {
               html += '    <p class="mui-ellipsis">.</p>'
            }
            html += '</div>'
            if (m.num > 0) {
                html += '    <span class="mui-badge mui-badge-danger">'+m.num+'</span>'
            } 
            html += '</a>'
            html += '</li>' 
            var messageList = $("#chatlist")
            if (messageList && flag == 0) {
                if (m.online) { 
                    $(html).prependTo("#chatlist")
                } else {
                    messageList.append(html)
                }
            }
            
            if (messageList && flag == 1) {
                $(html).prependTo("#chatlist")
            }
        },
        format : function(datetime) {
            var date 
            if (datetime) {
                date = new Date(parseInt(datetime*1000));//时间戳为10位需*1000，时间戳为13位的话不需乘1000
            }  else {
               date = new Date()
            }
            var year = date.getFullYear(),
                month = ("0" + (date.getMonth() + 1)).slice(-2),
                sdate = ("0" + date.getDate()).slice(-2),
                hour = ("0" + date.getHours()).slice(-2),
                minute = ("0" + date.getMinutes()).slice(-2),
                second = ("0" + date.getSeconds()).slice(-2);
                // 拼接
            // var result = year + "-"+ month +"-"+ sdate +" "+ hour +":"+ minute +":" + second;
            var result = hour +":"+ minute +":" + second 
            return result;
        }
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
    win['_'] = _ 
    _.init()
})(window)
