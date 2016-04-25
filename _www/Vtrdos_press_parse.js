// JavaScript Document
javascript:!function(){var e,t,r,n,o,u,l=document.querySelectorAll("tr"),i=[];for(o=0;o<l.length;o++)if(null!==l[o].querySelector("td.nowrap")){for(r=l[o],e={name:r.querySelector("td.nowrap").textContent,issues:[]},t=r.querySelectorAll("a.rpad"),u=0;u<t.length;u++)n={number:t[u].textContent,link:"http://vtrdos.ru/"+t[u].getAttribute("href")},e.issues.push(n);i.push(e)}popup=window.open("","","resizable=1;width=640,height=480"),popup.document.write(JSON.stringify(i))}();

// вот так  прямо в адресную строку press.php