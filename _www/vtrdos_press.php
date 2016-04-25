<?
ob_start();
if (!isset($_GET['p'])) { $n=1;} else {$n=$_GET['p'];}
$n--;
$n=$n*100+1;
$x=$n;
$a=file_get_contents("vtrdos_press_all.js");
$json=json_decode($a);
$str=array();
foreach ($json as $zine){
  foreach ($zine->issues as $issue) {
    $str[]=$zine->name.' '.$issue->number."\r\n".$issue->link."\r\n\r\n\r\n\r\n";
//    $str[]=$sys_link->text.': '.$sys_type->title."\r\n".$sys_link->url."\r\n \r\n".$sys_link->author."\r\n \r\n";
  }
}

for ($z=$n;$z<$n+100;$z++)
	if (trim($str[$z])!='') echo $x++.'.'.iconv('utf-8', 'cp866//TRANSLIT', $str[$z]);
ob_end_flush();
?>