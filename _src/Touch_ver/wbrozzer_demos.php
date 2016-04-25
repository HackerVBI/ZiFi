<?
include 'func.php';
dbconnect ();

// ob_start('ob_gzhandler');
ob_start();
//ob_implicit_flush(0); // отключаем неявную отправку буфера

$input_win=array('l','p');
getpost_ifset($input_win); 


// filters
foreach ($input_win as &$ai) $ai=htmlspecialchars($ai, ENT_QUOTES, 'win-1251');
unset($ai);
$demo_on_page=120;

if (!isset($p)) $p=1;

// $sql='select * from gift where substring(title,1,1)="'.$l.'" order by title ';

// if (!isset($l)) 
 $sql='select * from gift order by cid desc limit '.(($p-1)*$demo_on_page).','.$demo_on_page;

// if ($l=='@') $sql='select * from gift where substring(title,1,1) IN ("0", "1", "2", "3", "4", "5", "6", "7", "8", "9") order by title ';

// $rad=mq($sql);
// $all_gifts=mysql_num_rows($rad);

// echo $sql.$sql_l.' order by title limit '.(($num_page-1)*$gifts_on_page).','.$gifts_on_page;

/*
A brief history of vacuum cleaner nozzle attachments
http://zxaaa.untergrund.net/get.php?f=DEMO6/a_brief_history_of_vacuum_cleaner_nozzle_attachments.zip
2014
Gasman / Hooy-Program
United Kingdom

*/


$rz=mq($sql);
$x=0;
    while ($lx=mysql_fetch_array($rz))
    {

		$auth= explode('/', $lx['author']);		
		$authors='';
		foreach ($auth as $ax) 	$authors.=addslashes($ax).'/';

//		 $gfx= explode(';', $lx['gfx']);		
//		if (count($gfx)!=0)	echo '"gfx":"http://zxaaa.untergrund.net/'.$gfx[0].'",';


echo $x++.'.'.$lx['title']."
http://zxaaa.untergrund.net/get.php?f=".$lx['url'];
echo "
".$lx['year']."
".substr($authors,0,-1)."
".addslashes($lx['city'])."
";

    }
echo "

";
/* Здесь идет код скрипта, в нем не должно быть ob_flush, так как потом нельзя будет выдавать заголовки */
header('Content-Length: '.ob_get_length()); // если заголовки еще можно отправить, выдаем загловок Content-Length, иначе придется завершать передачу по закрытию

ob_end_flush();
exit;
?>