
function Jax()
{var loadingTimeout=400;var iframe;this.loadingFunction=function(){};this.doneLoadingFunction=function(){};this.stringify=function(arg){var c,i,l,o,u,v;switch(typeof arg){case'object':if(arg){if(arg.constructor==Array){o='';for(i=0;i<arg.length;++i){v=this.stringify(arg[i]);if(o&&(v!==u)){o+=',';}
if(v!==u){o+=v;}}
return'['+o+']';}else if(typeof arg.toString!='undefined'){o='';for(i in arg){v=this.stringify(arg[i]);if(v!==u){if(o){o+=',';}
o+=this.stringify(i)+':'+v;}}
return'{'+o+'}';}else{return;}}
return'';case'unknown':case'undefined':case'function':return u;case'string':arg=arg.replace(/"/g,"\\\"");l=arg.length;o='"';for(i=0;i<l;i+=1){c=arg.charAt(i);if(c>=' '){if(c=='\\'||c=='"'){o+='\\';}
o+=c;}else{switch(c){case'"':o+='\\"';break;case'\b':o+='\\b';break;case'\f':o+='\\f';break;case'\n':o+='\\n';break;case'\r':o+='\\r';break;case'\t':o+='\\t';break;default:c=c.charCodeAt();o+='\\u00';o+=Math.floor(c/16).toString(16);o+=(c%16).toString(16);}}}
return o+'"';default:return String(arg);}}
this.getRequestObject=function()
{if(window.XMLHttpRequest){http_request=new XMLHttpRequest();}else if(window.ActiveXObject){var msxmlhttp=new Array('Msxml2.XMLHTTP.4.0','Msxml2.XMLHTTP.3.0','Msxml2.XMLHTTP','Microsoft.XMLHTTP');for(var i=0;i<msxmlhttp.length;i++){try{http_request=new ActiveXObject(msxmlhttp[i]);}catch(e){http_request=null;}}}
if(!http_request){alert('Unfortunatelly you browser doesn\'t support this feature.');return false;}
return http_request;}
this.$=function(sId)
{if(!sId){return null;}
var returnObj=document.getElementById(sId);if(!returnObj&&document.all){returnObj=document.all[sId];}
return returnObj;}
this.addEvent=function(obj,type,fn){if(obj.attachEvent){obj['e'+type+fn]=fn;obj[type+fn]=function(){obj['e'+type+fn](window.event);}
obj.attachEvent('on'+type,obj[type+fn]);}else{obj.addEventListener(type,fn,false);}}
this.removeEvent=function(obj,type,fn){if(obj.detachEvent){obj.detachEvent('on'+type,obj[type+fn]);obj[type+fn]=null;}else{obj.removeEventListener(type,fn,false);}}
this.submitITask=function(comName,func,postData,responseFunc){var xmlReq=this.buildXmlReq(comName,func,postData,responseFunc,true);this.loadingFunction();if(!this.iframe){this.iframe=document.createElement('iframe');this.iframe.setAttribute("id",'ajaxIframe');this.iframe.setAttribute("height",0);this.iframe.setAttribute("width",0);this.iframe.setAttribute("border",0);this.iframe.style.visibility='hidden';document.body.appendChild(this.iframe);this.iframe.src=xmlReq;}else{this.iframe.src=xmlReq;}}
this.extractIFrameBody=function(iFrameEl){var doc=null;if(iFrameEl.contentDocument){doc=iFrameEl.contentDocument;}else if(iFrameEl.contentWindow){doc=iFrameEl.contentWindow.document;}else if(iFrameEl.document){doc=iFrameEl.document;}else{alert("Error: could not find sumiFrame document");return null;}
return doc.body;}
this.buildXmlReq=function(comName,func,postData,responseFunc,iframe){var xmlReq='';if(iframe){xmlReq+='?';}
else{xmlReq+='&';}
xmlReq+='option='+comName;xmlReq+='&no_html=1';xmlReq+='&task=azrul_ajax';xmlReq+='&func='+func;if(postData){xmlReq+="&"+postData;}
return xmlReq;}
this.submitTask=function(comName,func,postData,responseFunc){var xmlhttp=this.getRequestObject();var targetUrl=jax_live_site;xmlhttp.open('POST',targetUrl,true);xmlhttp.onreadystatechange=function(){if(xmlhttp.readyState==4){if(xmlhttp.status==200){jax.doneLoadingFunction();jax.processResponse(xmlhttp.responseText);}else{}}}
var id=1;var xmlReq=this.buildXmlReq(comName,func,postData,responseFunc);this.loadingFunction();xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded');xmlhttp.send(xmlReq);}
this.processIResponse=function(){jax.doneLoadingFunction();var resp=(this.extractIFrameBody(this.iframe).innerHTML);resp=resp.replace(/&lt;/g,"<");resp=resp.replace(/&gt;/g,">");resp=resp.replace(/&amp;/g,"&");resp=resp.replace(/&quot;/g,'"');resp=resp.replace(/&#39;/g,"'");this.processResponse(resp);}
this.processResponse=function(responseTxt){var result=eval(responseTxt);for(var i=0;i<result.length;i++){var cmd=result[i][0];var id=result[i][1];var property=result[i][2];var data=result[i][3];var objElement=this.$(id);switch(cmd){case'as':if(objElement){eval("objElement."+property+"=  data \; ");}
break;case'al':if(data){alert(data);}
break;case'ce':this.create(id,property,data);break;case'rm':this.remove(id);break;case'cs':var scr=id+'(';if(this.isArray(data)){scr+='(data[0])';for(var l=1;l<data.length;l++){scr+=',(data['+l+'])';}}else{scr+='data';}
scr+=');';eval(scr);break;default:alert("Unknow command: "+cmd);}}
delete responseTxt;}
this.isArray=function(obj){if(obj){return obj.constructor==Array;}
return false;}
this.buildCall=function(comName,sFunction){}
this.icall=function(comName,sFunction){var arg="";if(arguments.length>2){for(var i=2;i<arguments.length;i++){var a=arguments[i];if(this.isArray(a)){arg+="arg"+i+"="+this.stringify(a)+"&";}else if(typeof a=="string"){var t=new Array('_d_',encodeURIComponent(a));arg+="arg"+i+"="+this.stringify(t)+"&";}else{var t=new Array('_d_',encodeURIComponent(a));arg+="arg"+i+"="+this.stringify(t)+"&";}}}
if(jax_site_type=='1.5'){this.submitTask(comName,sFunction,arg);}else{this.submitITask(comName,sFunction,arg);}}
this.call=function(comName,sFunction){var arg="";if(arguments.length>2){for(var i=2;i<arguments.length;i++){var a=arguments[i];if(this.isArray(a)){arg+="arg"+i+"="+this.stringify(a)+"&";}else if(typeof a=="string"){a=a.replace(/"/g,"&quot;");var t=new Array('_d_',encodeURIComponent(a));arg+="arg"+i+"="+this.stringify(t)+"&";}else{var t=new Array('_d_',encodeURIComponent(a));arg+="arg"+i+"="+this.stringify(t)+"&";}}}
this.submitTask(comName,sFunction,arg);}
this.create=function(sParentId,sTag,sId){var objParent=this.$(sParentId);objElement=document.createElement(sTag);objElement.setAttribute('id',sId);if(objParent){objParent.appendChild(objElement);}}
this.remove=function(sId){objElement=this.$(sId);if(objElement&&objElement.parentNode&&objElement.parentNode.removeChild)
{objElement.parentNode.removeChild(objElement);}}
this.getFormValues=function(frm){var objForm;objForm=this.$(frm);var postData=new Array();if(objForm&&objForm.tagName=='FORM'){var formElements=objForm.elements;var assCheckbox=new Array();var assCntIdx=0;var startIdx=0;if(formElements.length>0){for(var i=0;i<formElements.length;i++){if(!formElements[i].name){continue;}
if(formElements[i].type&&(formElements[i].type=='radio'||formElements[i].type=='checkbox')&&formElements[i].checked==false){continue;}
var name=formElements[i].name;if(name){if(formElements[i].type=='select-multiple'){postData[i]=new Array();for(var j=0;j<formElements[i].length;j++){if(formElements[i].options[j].selected===true){var value=formElements[i].options[j].value;postData[i][j]=new Array(name,encodeURIComponent(value));}}
startIdx++;}else if(formElements[i].type=='checkbox'){if(assCheckbox.indexOf(formElements[i].name)==-1){assCheckbox[assCntIdx]=formElements[i].name
assCntIdx++;}}else{var value=formElements[i].value;value=value.replace(/"/g,"&quot;");postData[i]=new Array(name,encodeURIComponent(value));}
startIdx++;}}}
if(assCheckbox.length>0){for(var i=0;i<assCheckbox.length;i++){var objCheckbox=document.getElementsByName(assCheckbox[i]);if(objCheckbox){if(objCheckbox.length>1){postData[i+startIdx]=new Array();var tmpIdx=0;for(var j=0;j<objCheckbox.length;j++){if(objCheckbox[j].checked){var value=objCheckbox[j].value;value=value.replace(/"/g,"&quot;");postData[i+startIdx][j]=new Array(assCheckbox[i],encodeURIComponent(value));tmpIdx++;}}
if(tmpIdx>0){startIdx++;}}else{if(objCheckbox[0].checked){var value=objCheckbox[0].value;value=value.replace(/"/g,"&quot;");postData[i+startIdx]=new Array(assCheckbox[i],encodeURIComponent(value));startIdx++;}}}}}}
return postData;}}
function jax_iresponse(){jax.processIResponse();}
var jax=new Jax();