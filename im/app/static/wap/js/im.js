$(function(){
    var _ = {}; 
    _.init = function() {
        var self = this;
        _.face.init(); //工具处理   
        _.comet.init(); //连接  
        _.oldMessageLog(); //旧的聊天记录         
    }; 
    
    _.auto = function () {
        $('#messageList')[0].scrollTop = 1000000; 
    }
    
    _.alert = function(msg) {
        var domsg = $("#domsg"); 
        if (domsg.length < 1)
        {
            domsg = document.createElement("div");
            domsg.id = "domsg";
            domsg.className = "popupWindow";
            var string = '<div class="hint"><div class="text" id="msgtext" style="padding: 20px 0;" >'+ msg +'</div>';
            string += '<div class="btnBox"><a class="btnStyle btn01" id="doconfig" style="width: 100%;" >确定</a>';
            string += '</div></div>';
            domsg.innerHTML = string;           
            document.body.appendChild(domsg);
            
            $("#doconfig").click(function() {
                $("#domsg").css("display","none"); 
            });
        }
        $("#domsg").css("display","block");  
        $("#msgtext").html(msg);
    }
       
    _.checkclient =  function () { //检测客户端是pc端 还是移动端
        var userAgentInfo = navigator.userAgent;
        var Agents = ["Android", "iPhone",
                    "SymbianOS", "Windows Phone",
                    "iPad", "iPod"];
        var flag = true;
        for (var v = 0; v < Agents.length; v++) {
            if (userAgentInfo.indexOf(Agents[v]) > 0) {
                flag = false;
                break;
            }
        }
        return flag;
    }
    
    _.face = {
         init : function(){
              var self = this;
               self.showFace();
               self.typeFace(); 
         }, 
         showFace : function(){ //展示工具按钮   
                $('#web_wechat_face').click(function () {
                    $('.face_box').toggleClass('hide');  
                     _.auto(); 
                });
         },
         typeFace : function(){    //切换工具栏目 并绑定事件 
                $('#face_box .exp_hd li').click(function () {
                    var self = $(this);
                    var i = self.data('i'); 
                     $("#face_box .exp_hd li, #face_box .exp_bd div").each(function(){
                            $(this).removeClass('active');//先抹去所有的 选中状态
                     });
      
                    self.addClass('active'); //本次的为选中状态
                    $('#face_box .exp_bd div').eq(i).addClass('active');  
                    _.auto();
                });  
                 
                //表情  
                $('#face_box_qq a').click(function () {
                    _.face.getOneFace(this);
                });
                
                //图片
                $('#face_box_pic_file').live("change", function () {
                      _.upload.on(this); 
                     $('#face_box_pic_file').replaceWith($('#face_box_pic_file').clone(true)); 
                });
                 
                //语音
                $('#face_box_audio_file').live("change", function () {
                      _.upload.on(this); 
                      $('#face_box_pic_file').replaceWith($('#face_box_pic_file').clone(true)); 
                }); 
         },
         getOneFace : function(self){
               var self = $(self);
               var html = '[' + self.attr('title') + ']';  
               $('#editArea').html($('#editArea').html() + html);  
         },
         handleface : function(str){  //表情过滤     str="[得意]ddd[gg[6 ][发呆]6]]jjjj[发呆]j";
                var newstr = str; 
                 var i=0;  var x=0;  var arr=[];
                 var fn=function(s,y,p) {
                   var a=fn.arguments,l=a.length,s=a[0],p=a[l-2];
                   if(s=="["){   i+=1;   if (i==1) {  x=p;  }   }
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
                var domObj = $('#face_box_qq a');   
            
                for (var m in arr)   {
                   if ((arr[m]).length < 1 || (arr[m]).length > 5){ continue;}  //不合法表情提前过滤
                         domObj.each(function(index, element){ 
                             var title = element.getAttribute("title"); 
                           if ( arr[m] == title ){
                                  var ls = '[' + title + ']';   
                                 newstr =  newstr.replace(ls,  element. innerHTML);
                                 newstr = newstr.replace('id="editArea"',  "");//替换重要id
                           }
                    });  
                 }
                return newstr;
         }
    }; 
    
    
    _.upload ={
           on : function (dom){
                var self = this;
                var mark = arguments[1] != undefined ? arguments[1] : null;
                if (typeof(_.upload.start) == 'function') {
                    self.start(dom, mark);
                }
                
                $.ajaxFileUpload({
                    url : $(dom).attr('url'),
                    timeout : 27000,
                    data : {},//{'path' : $(dom).attr('path'), 'crop' : '其他字段', 'compress' : '其他字段'},
                    secureuri : false,
                    fileElementId : $(dom),
                    dataType: 'json',
                    success : function(data) {  
                        if (data['success']) {//成功  
                            self.success(data); 
                        } else {  
                            self.feild(data);   //失败
                        }
                    }
                })
                return false; 
           },
           start : function (dom, mark){
                //console.log('上传即将开始');
           },
           success : function(data){   //上传成功 
             //   if (_.checkclient()) {
             //       _.websocket.send(data['data']['url']);
            //    }else{
                    _.comet.send(data['filename']);
            //    }
                $('#web_wechat_face').click();
           },
           feild : function(data){
               //上传失败
               //console.log('遇到错误');
               //console.log(data);
               }
       }
    
      
    _.comet = {
        msg_index : 0,
        init:function (){
            var self = this; 
            $('#btn_send').click(function(){
                self.send(); 
                $('.face_box').addClass("hide");
            });  
            _.comet.sub();
            return true;
        },
        fun : function (res){
            // console.log(res); 
            var self = this;  
            if (res)
            {
                for (var i = 0; i < res.length; i++) {
                   // console.log(i+":"+res[i]); 
                    if (res[i]['status'] > 0) {
                        var data = res[i] ;// JSON.stringify(res['data']) ;  
                            _.render.show(data);
                        }
                          
                        if (res[i]['idx_read'] > 0) {
                            self['msg_index'] = res[i]['idx_read'];
                        }
                    };
            }
                return true;
        },  
        sub : function(){
            var self = this; 
            var ajaxTimeoutTest =  $.ajax({
                    type : "GET",
                    url :"/im/sub",
                    global: true, //希望产生全局的事件
                    data : {
                        idx_read:self['msg_index'], 
                        roomid:IM['data']['roomid'],
                        IMrand:IM['data']['IMrand'],
                        IMtoken:IM['data']['IMtoken']
                    },
                    timeout : 27000,
                    //cache:true,
                    async: true, //是否异步
                    contentType:'application/x-www-form-urlencoded;charset=utf-8',
                    dataType:"jsonp", // 数据格式指定为jsonp 
                     //jsonp:"callback", //传递给请求处理程序或页面的，用以获得jsonp回调函数名的参数名默认就是callback
                    // jsonpCallback:"getName",   // 指定回调方法
                    success:function(data){
                         _.comet.fun(data); 
                         _.comet.sub(); //再次发起
                         return true; 
                    },
                    error:function (res, status, errors){
                        setTimeout(function (){ _.comet.sub(); }, 3500);
                        //console.log(res);
                        //console.log(status);
                        //console.log(errors);
                        //console.log(XMLHttpRequest.status);    200
                        //console.log(XMLHttpRequest.readyState);   4
                        //console.log(XMLHttpRequest.responseText); _.comet.fun("{\"status\":0,\"timeline\":1468236362,\"tips\":\"timeout\"}");
                        //console.log(textStatus);              parsererror
                        //console.log(errorThrown);             ReferenceError: _ is not defined
                        //console.log(textStatus);              parsererror
                    },                       
                    complete : function(XMLHttpRequest,status){ //请求完成后最终执行参数
                    	if(status=='timeout'){//超时,status还有success,error等值的情况
                    	 　 ajaxTimeoutTest.abort();
                    	　　//console.log("--------");　
                    	}
                    }
                });
                return true;
            },
            send : function(picture){      //发送消息
                var  data = {}; 
                var self = this; 
                var msg = $('#editArea').html(); //拿到输入框内容
                    data["ret"]  = 0; //0 发送成功
                    data["pic"]  = 0; 
                    data["roomid"]  = IM['data']['roomid'];
                    data["uid"]  = IM['data']['user']['uid'];  
                    data["touid"] = (IM['data']['to']) && (IM['data']['to']['uid']) ? IM['data']['to']['uid'] : 0 ; 
                    data["me"]   = IM['data']['user'];
                    if (picture && picture.length > 5){
                         data["pic"]  = picture;  
                    }
                    
                    if ( $.trim(msg) == "" || (msg.length < 1 ) ){
                        if (data["pic"] == 0) {
                             _.alert('请输入内容再发送');
                             return false;
                        }
                    }
                    data["msg"]  = msg;
                    
                    $.ajax({
                        type : "POST",
                        url :"/im/pub",
                        global: true, //希望产生全局的事件
                        data : { 
                        	data: JSON.stringify(data), 
                            test: "test2pm",
                            roomid: IM['data']['roomid']
                        },
                        timeout : 27000,
                        //cache:true,
                        async: true, //是否异步
                        contentType:'application/x-www-form-urlencoded;charset=utf-8',
                        dataType:"json", // 数据格式指定为jsonp 
                         //jsonp:"callback", //传递给请求处理程序或页面的，用以获得jsonp回调函数名的参数名默认就是callback
                        // jsonpCallback:"getName",   // 指定回调方法
                        beforeSend:function(){ 
                        	return console.log('发送中...');
                        },
                        success:function(data){
                        	if (! data.success)
                        	{
                        		return location.href="/index"
                        	}	
                            if (data.status < 1)
                            {
                            	return _.alert('消息发送失败/(ㄒoㄒ)/~~');
                            }
                             return ;
                        },
                        error:function (res, status, errors){
                        	return _.alert('消息发送失败/(ㄒoㄒ)/~~'); 
                        	//console.log(res);
                        	//console.log(status);
                        	//console.log(errors);
                    },
                    complete:function(){
                  	return console.log('发送成功');
                 }
            }); 
                        
            $('#editArea').html(""); 
            return true;
        }
    }
    
    
    _.websocket = {
        ws : null,
        init : function(){
               var self = this; 
                self.connect();
               setInterval(function (){
                   if (self['ws'] === null){ 
                        self.connect();
                   }
                   
                 }, 3000);  
                
               $('#btn_send').click(function(){ 
                    self.send();
                    $('.face_box').addClass("hide");
               }); 
        }, 
        connect : function(){ //连接 
            var self = this;
            if (self['ws'] != null && self['ws'].readyState == 1) {
                return self['ws'];
            } 
            if ("WebSocket" in window) {
                self['ws'] = new WebSocket( IM['data']['socket']); 
                self['ws'].onopen = function() {
                    //console.log('成功进入聊天室');
                } 
                self['ws'].onmessage = function(event) {
                    var data = eval(event.data) ;
                    _.render.show( JSON.parse(data[2]) );
                }
                self['ws'].onclose = function() {
                    //console.log("已经和服务器断开");
                } 
                self['ws'].onerror = function(event) {
                    //console.log("error " + event.data);
                }
            } else {
                _.alert("你的浏览器不支持 WebSocket!");
            }
            return self['ws'];
        },
        send : function(picture){//发送消息
            var self = this; 
            var  data = {}; 
            if (self['ws'] != null && self['ws'].readyState == 1) {
                var msg = $('#editArea').html(); //拿到输入框内容
                    data["ret"]  = 0; //0 发送成功
                    data["pic"]  = 0;
                    data["roomid"]  = IM['data']['roomid'];
                    data["uid"]  = IM['data']['user']['uid']; 
                    
                    data["touid"] = (IM['data']['to']) && (IM['data']['to']['uid']) ? IM['data']['to']['uid'] : 0 ; 
                    
                    data["me"]   = IM['data']['user'];
                    if (picture && picture.length > 5){
                         data["pic"]  = picture;  
                    }
                    if ($.trim(msg) == "" || (msg.length < 1 ) ) {
                        if (data["pic"] == 0) {
                             _.alert('请输入内容再发送');
                             return false;
                        }
                    }
                    data["msg"]  = msg; 
                    self['ws'].send(JSON.stringify(data));
            } else {
                    //console.log('请先进入聊天室');
            } 
             $('#editArea').html("");
             return true;
        }, 
        close : function(){     //关闭 
            var self = this;
            if (self['ws'] != null && self['ws'].readyState == 1) {
                self['ws'].close();
                //console.log("发送断开服务器请求");
            } else {
                //console.log("当前没有连接服务器")
            }
            return false;
        } 
   }
    
   _.render = {
	 show : function(data){ //渲染消息 
          var self = this; 
          var res =data; 
          var html = null; 

          res['response_timeline'] = new Date(parseInt(res['response_timeline']) * 1000).toLocaleString().replace(/年|月/g, "-").replace(/日/g, " ");  
          if (res['msg'] && (res['msg']).length > 2){
              res['msg'] = _.face.handleface( res['msg'] );
          }
          
          if (res['uid'] == IM['data']['user']['uid']){
              //我自己说的话
              html = self.message_me(IM['data']['user']['face'], IM['data']['user']['nickname'],  res['response_timeline'] , res['msg'], res['pic']);
          }else{
             //别人发消息给我的模板
              var face = res['me']['face'] ||  "/static/wap/img/portrait.jpg"
              html = self.message(face, res['me']['nickname'],  res['response_timeline'] , res['msg'], res['pic']);
          }
          //插入新消息
          var messageList = $("#messageList")
          messageList.append($(html).hide().fadeIn('slow')); 
           
          //判断长度 是否需要删除 
          if (messageList.children().length > 26) {
                messageList.children().first().remove(); 
          }
     },  
      message : function (face, nickname, time, msg, ispic){ //别人发消息给我的模板； 
          var str = '<div class="message">  ';
           str += '        <img src="'+face+'" class="avatar">  ';
           str += '        <div class="content">  ';
           str += '             <div class="nickname">'+nickname+'<span class="time">'+time+'</span></div> '; 
           str += '             <div class="bubble bubble_default left">  ';
           str += '                <div class="bubble_cont">  '; 
              if (ispic && ispic.length > 5){
                str += '<div style="min-height:10px;"  class="picture" onclick="window._.alert(this.innerHTML);">  ';
              
                 str += '<img  src="'+ispic+'" class="msg-img">  ';
               
                str += ' </div> ';
             } 
             if (msg.length > 0){
                 str += '         <div class="plain">  ';
                 str += '                <pre>'+msg+'</pre>';  
                 str += '            </div>  ';
             } 
          str += '                 </div>  ';
          str += '             </div>  ';
          str += '          </div> '; 
          str += '     </div>';
         return str;
      }, 
      message_me : function (face,nickname, time, msg, ispic){ //我自己发消息模板； 
          var str = '<div class="message me">  ';
            str += ' <img src="'+face+'" class="avatar">  ';
            str += '<div class="content">  ';
            str += '    <div class="nickname"><span class="time">'+time+'    '+ nickname +'</span></div>  ';
            str += '     <div class="bubble bubble_primary right">  ';
            str += '       <div class="bubble_cont">  ';
            
            if (ispic && ispic.length > 5){
                    str += '<div style="min-height:10px;"  class="picture" onclick="window._.alert(this.innerHTML);">  ';
                    str += '<img  src="'+ispic+'" class="msg-img">  ';
                    str += ' </div> ';
            }
            
            if (msg.length > 0){
                     str += '         <div class="plain">  ';
                     str += '                <pre>'+msg+'</pre>';  
                     str += '            </div>  ';
            } 
            str += '         </div>  ';
            str += '      </div>  ';
            str += '   </div>  ';
            str += '  </div>';
           return str;
      }
    } 
        
   _.oldMessageLog = function () {
       var oldmessage = IM['data']['oldmessage'];
       if (! oldmessage) 
       {
    	   return ;
       }
       for (var index in oldmessage) 
       {
           if (oldmessage[index]['suid'] == IM['data']['user']['uid'])
           {
               //自己说的话 
               oldmessage[index]['me'] =  IM['data']['user'];
               _.render.show(oldmessage[index]); 
           }else{
               //别人发消息给我的模板； 
        	   _.render.show(oldmessage[index]); 
           }
       }
    }
 
    _.data =  IM.data;
    _.init();
    _.auto();  //自适应  
    window._ =_ ;
})

