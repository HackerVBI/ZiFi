<?
ob_start();
if (!isset($_GET['p'])) { $n=1;} else {$n=$_GET['p'];}
$n--;
$n=$n*100+1;
$x=$n;
$a=file_get_contents("vtrdos_system_all.js");
$json=json_decode($a);
$str=array();
foreach ($json as $sys_type){ 
  foreach ($sys_type->links as $sys_link) {
    $str[]=$sys_link->text.': '.$sys_type->title."\r\n".$sys_link->url."\r\n\r\n".$sys_link->author."\r\n\r\n";
//	echo $x++.'.'.$lx['title']."\r\nhttp://zxaaa.untergrund.net/get.php?f=".$lx['url']."\r\n".$lx['year']."\r\n".substr($authors,0,-1)."\r\n".addslashes($lx['city'])."\r\n";
  }
}

for ($z=$n;$z<$n+100;$z++)
	if (trim($str[$z])!='') echo $x++.'.'.iconv('utf-8', 'cp866//TRANSLIT', $str[$z]);
ob_end_flush();
?>