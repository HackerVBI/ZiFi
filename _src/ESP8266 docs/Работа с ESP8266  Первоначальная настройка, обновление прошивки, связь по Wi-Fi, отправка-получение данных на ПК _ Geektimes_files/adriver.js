function adriver(ph, prm, defer){ 
	if(this instanceof adriver){
		var p = null;
		if (typeof(ph) == "string"){
			p = document.getElementById(ph);
		}else{
			p = ph; ph = p.id;
		}

		if (!p) {
			if (!adriver.isDomReady) adriver.onDomReady(function(){new adriver(ph, prm, defer)});
			return null
		}
		if (adriver.items[ph]){return adriver.items[ph]}

		adriver.items[ph] = this;
		this.p = p;
		this.defer = defer;
		this.prm = adriver.extend(prm, {ph: ph});

		this.loadCompleteQueue = new adriver.queue();
		this.domReadyQueue = new adriver.queue(adriver.isDomReady);
		var my = this;
		adriver.initQueue.push(function(){my.init()});
		return this;
	}else{
		return arguments.length ? adriver.items[ph] : adriver.items;
	}
}

adriver.prototype = {
	isLoading: 0,

	init: function(){},
	loadComplete: function(){},
	domReady: function(){},

	onLoadComplete: function(f){
		var my = this;
		this.loadCompleteQueue.push(function(){f.call(my)});
		return this;
	},
	onDomReady: function(f){
		this.domReadyQueue.push(f);
		return this;
	},
	reset: function(){
		this.loadCompleteQueue.flush();
		this.domReadyQueue.flush(adriver.isDomReady);
		return this;
	}
}

adriver.loadScript = function(req){
	try {
		req = req.replace(/!\[rnd\]/,Math.round(Math.random()*9999999));
		var head = document.getElementsByTagName("head")[0];
		var s = document.createElement("script");
		s.setAttribute("type", "text/javascript");
		s.setAttribute("charset", "windows-1251");
		s.setAttribute("src", req);
		s.onreadystatechange = function(){if(/loaded|complete/.test(this.readyState)){s.onload = null; head.removeChild(s)}};
		s.onload = function(e){if(head&&s)head.removeChild(s)};
		head.insertBefore(s, head.firstChild);
	}catch(e){}
}

adriver.extend = function(){
	var l = arguments[0];
	for (var i = 1, len = arguments.length; i<len; i++){
		var r = arguments[i];
		for (var j in r){
			if(r.hasOwnProperty(j)){
				if(r[j] instanceof Object){if(l[j]){adriver.extend(l[j], r[j]);}else{l[j] = adriver.extend(r[j] instanceof Array ? [] : {}, r[j]);}}else{l[j] = r[j];}
			}
		}
	}
	return l
}

adriver.queue = function(flag){this.q = []; this.flag = flag ? true: false}
adriver.queue.prototype = {
	push: function(f){this.flag ? f() : this.q.push(f)},
	unshift: function(f){this.flag ? f() : this.q.unshift(f)},
	execute: function(flag){var f; var undefined; while (f = this.q.shift()) f(); if(flag == undefined) flag=true; this.flag = flag ? true : false},
	flush: function(flag){this.q.length = 0; this.flag = flag ? true: false}
}

adriver.Plugin = function(id){
	if(this instanceof adriver.Plugin){
		if(id && !adriver.plugins[id]){
			this.id = id;
			this.q = new adriver.queue();
			this.loadingStatus = 0;
			adriver.plugins[id] = this;
			return this;
		}
	}
	return adriver.plugins[id];
}
adriver.Plugin.prototype = {
	load: function(){
		this.loadingStatus = 1;
		var suffix = this.id.substr(this.id.lastIndexOf('.')+1);
		var pluginPath = adriver.pluginPath[suffix] || adriver.defaultMirror + "/plugins/";
		adriver.loadScript(pluginPath + this.id + ".js");
	},
	loadComplete: function(){this.loadingStatus = 2; this.q.execute(); return this},
	onLoadComplete: function(f){this.q.push(f); return this}
}
adriver.Plugin.require = function(){
	var me = this, counter = 0;
	this.q = new adriver.queue();

	for (var i = 0, len = arguments.length; i < len; i ++){
		var p = new adriver.Plugin(arguments[i]);
		if(p.loadingStatus != 2){
			counter++;
			p.onLoadComplete(function(){if(counter-- == 1){me.q.execute()}});
			if(!p.loadingStatus) p.load();
		}
	}
	if(!counter){this.q.execute()}
}
adriver.Plugin.require.prototype.onLoadComplete = function(f){this.q.push(f); return this}

adriver.onDomReady = function(f){
	adriver.domReadyQueue.push(f);
}
adriver.onBeforeDomReady = function(f){
	adriver.domReadyQueue.unshift(f);
}
adriver.domReady = function(){
	adriver.isDomReady = true;
	adriver.domReadyQueue.execute();
}
adriver.checkDomReady = function(f){
	try {
		var d = document, oldOnload = window.onload;
		if(/WebKit/i.test(navigator.userAgent)){(function(){/loaded|complete/.test(d.readyState) ? f() : setTimeout (arguments.callee, 100)})()}
		else if(d.addEventListener){d.addEventListener("DOMContentLoaded", f, false)}
		else if(document.attachEvent){
			var doScrollCheck = function() {
				if ( adriver.isDomReady ) {return;}
				try {
					document.documentElement.doScroll("left");
				} catch(e) {
					setTimeout( doScrollCheck, 1 );
					return;
				}
				f();
			}
			var DOMContentLoaded = function(){
				if ( document.readyState === "complete" ) {
					document.detachEvent( "onreadystatechange", DOMContentLoaded );
					f();
				}
			}
			document.attachEvent( "onreadystatechange", DOMContentLoaded );
			window.attachEvent( "onload", function(){if(adriver.isDomReady)return;f();});
			try {
				toplevel = window.frameElement == null;
			} catch(e) {}
			if ( document.documentElement.doScroll && toplevel ) {
				doScrollCheck();
			}
		}
	} catch (e){}
}

adriver.onLoadComplete = function(f){
	adriver.loadCompleteQueue.push(f);
	return adriver;
}
adriver.loadComplete = function(){
	adriver.loadCompleteQueue.execute();
	return adriver;
}

adriver.setDefaults = function(defaults){adriver.extend(adriver.defaults, defaults)}
adriver.setOptions = function(options){adriver.extend(adriver.options, options)}
adriver.setPluginPath = function(path){adriver.extend(adriver.pluginPath, path)}

adriver.start = function(){
	adriver.version = "2.3.4";
	adriver.items = {};
	adriver.defaults = {tail256: escape(document.referrer || 'unknown')};
	adriver.options = {};
	adriver.plugins = {};
	adriver.pluginPath = {};
	adriver.redirectHost = "https://ad.adriver.ru";
	adriver.defaultMirror = "https://content.adriver.ru";
	adriver.isDomReady = false;
	adriver.domReadyQueue = new adriver.queue();
	adriver.loadCompleteQueue = new adriver.queue();
	adriver.initQueue = new adriver.queue();

	adriver.checkDomReady(adriver.domReady); 

	new adriver.Plugin.require("autoUpdate.adriver").onLoadComplete(function(){
		adriver.initQueue.execute();
	});
}

adriver.start();