var ar_rhost = 'ad.adriver.ru', ar_alt = '', ar_target = '_blank', ar_html = '', ar_pass = '', ar_plugin = false, ar_bid, ar_width, ar_height, ar_sid, ar_pz, ar_ad, ar_bn, ar_bt, ar_ntype, ar_nid, ar_xpid, ar_rnd, ar_ref, ar_redirect, ar_domain, ar_CompPath, ar_place, ar_l, ar_t, ar_sliceid;

function ar_parseURL(){
	var p = location.search.substring(1).split('&'), param, v;
	for(var i in p){
		param = p[i].split('=');
		if(typeof(v = param[1]) != 'undefined' && (param[0] == 'html_params')){
			ar_parseParams(unescape(v)); return;
		}
	}
}

function ar_parseParams(p){
	var param, v;
	p = p.split('&');
	for(var i in p){
		param = p[i].split('=');
		if(typeof(v = param[1]) != 'undefined'){
			switch(param[0]){
				case 'domain':	ar_domain = v; break;
				case 'rhost':	ar_rhost = v; break;
				case 'bid':		ar_bid = v; break;
				case 'sid':		ar_sid = v; break;
				case 'width':	ar_width = v; break;
				case 'height':	ar_height = v; break;
				case 'rnd':		ar_rnd = v; break;
				case 'ar_place':	ar_place = v; break;
				case 'ar_l':	ar_l = v; break;
				case 'ar_t':	ar_t = v; break;
				case 'pz':		ar_pz = v; break;
				case 'ad':		ar_ad = v; break;
				case 'bt':		ar_bt = v; break;
				case 'bn':		ar_bn = v; break;
				case 'ar_sliceid':	ar_sliceid=v; break;
				case 'ntype':	ar_ntype = v; break;
				case 'nid':		ar_nid = v; break;
				case 'ref':		ar_ref = v; break;
				case 'target':	ar_target = v; break;
				case 'url':		ar_redirect = unescape(v); break;
				case 'CompPath':	ar_CompPath = unescape(v); break;
				case 'ar_pass':	ar_pass = unescape(unescape(v)); break;
				case 'xpid':	ar_xpid = v; break;
			}
		}
	}
}

function ar_p(param, value){
	return typeof(value) == 'undefined' ? '' : param + '=' + value ;
}

function httplize(s){
	return ((/^\/\//).test(s)?location.protocol:'')+s
}

function ar_addEvent(e,t,f){
	if (e.addEventListener) { e.addEventListener(t, f, false); }
	else if (e.attachEvent) { e.attachEvent('on'+t, f); }
}

var ar_clickCoord = {
	c: window,
	_putRes: function (res, el) {
		var link = el.href || el; // el = {object|string}

		function put(custom, n, val) {
			var r = new RegExp(n + '=.*?(;|$)', 'i');
			custom = r.test(custom) ? custom.replace(r, n + '=' + val + '$1') : (custom + (custom ? ';' : '') + n + '=' + val);
			return custom;
		}

		if (link.indexOf('custom=') !== -1) {
			link = link.replace(/(?:custom=(.*?)(&|$))/i, function (s, custom, end) {
				custom = put(custom, 201, res.x);
				custom = put(custom, 202, res.y);
				custom = put(custom, 206, 'js');

				return 'custom=' + custom + end;
			});
		} else { link += '&custom=201=' + res.x + ';202=' + res.y + ';206=js'; }

		if (el.href) el.href = link;

		return link;
	},
	_getXY: function (e) {
		var x = e.pageX, y = e.pageY;

		function getScreenGeometry(){
			var g = {}, d = ar_clickCoord.c.document, db = d.body, de = d.documentElement, cm = d.compatMode == 'CSS1Compat';

			g.sl = ar_clickCoord.c.pageXOffset || cm && de.scrollLeft || db.scrollLeft;
			g.st = ar_clickCoord.c.pageYOffset || cm && de.scrollTop || db.scrollTop;

			return g;
		}

		if (e.pageX == null && e.clientX != null ) {
			var sg = getScreenGeometry();
			x = e.clientX + sg.sl;
			y = e.clientY + sg.st;
		}

		return {x: x, y: y};
	},
	calc: function (ev, link) {
		var res = this._getXY(ev);
		return this._putRes(res, link);
	}
};

ar_parseURL();

ar_redirect = typeof(ar_redirect) == 'undefined' ? httplize('//' + ar_rhost + '/cgi-bin/click.cgi' +
					ar_p('?bid', ar_bid) + ar_p('&pz', ar_pz) + ar_p('&ad', ar_ad) +
					ar_p('&sid', ar_sid) + ar_p('&bt', ar_bt) + ar_p('&bn', ar_bn) +
					ar_p('&ntype', ar_ntype) + ar_p('&nid', ar_nid) + ar_p('&rnd', ar_rnd) +
					ar_p('&xpid', ar_xpid) + ar_p('&ref', ar_ref) + ar_p('&rleurl','')) : ar_redirect;

if(typeof(ar_CompPath) == 'undefined'){
	var ar_CompPath = location.href.substring(0, location.href.indexOf('index.html'));
}

function ar_callLink(options) {
	options = options || {};

	var target = options.target || ar_target,
		event = options.event || {},
		cgiHref = ar_redirect + escape(options.other || ''),
		w = window;

	if (event.pageX || event.clientX) {
		cgiHref = ar_clickCoord.calc(event, cgiHref);
	}

	switch (target) {
		case '_top': w.top.location = cgiHref; break;
		case '_self': w.document.location = cgiHref; break;
		default: w.open(cgiHref);
	}

	return false;
}

function ar_sendPixel(src) {
	function checkRnd(s) { return s.replace(/!\[rnd\]/g, ar_rnd); }

	if ((location.href.indexOf('mngcgi') != -1) || (!src)) { return; }
	src = httplize(checkRnd(src));

	var d = document, b = d.body;
	if(b){
		var i = document.createElement('IMG');
		i.style.position = 'absolute'; i.style.width = i.style.height = '0px';
		i.onload = i.onerror = function(){b.removeChild(i);};
		i.src=src;
		b.insertBefore(i, b.firstChild);
	}
	else{new Image().src = src;}
}