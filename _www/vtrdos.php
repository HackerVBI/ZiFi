<?
  $db=mysql_connect("localhost", "ts", "L4CDHC9j5UwnVZQ2") or die ("Could not connect to MySQL server!");
  mysql_select_db("ts",$db);
	mysql_query('SET NAMES cp866;');

ob_start();

$on_page=100;
if (!isset($_GET['p'])) { $n=1;} else {$n=$_GET['p'];}
	
if ($_GET['t']=='g') $type=array('EN','D','RE','RU','T');
if ($_GET['t']=='p') $type='PRESS';
if ($_GET['t']=='s') $type='SOFT';


	$sql='select * from vtrdos where type';
	if ($_GET['t']=='g')
	{
	$sql.=' in ('; 
		foreach ($type as $a) $sql.='"'.$a.'",';
		$sql=substr($sql,0,-1).')';
	} else {$sql.= '="'.$type.'"';}

if (isset($_GET['s'])) $sql.=' and (LOWER(name) like "%'.strtolower($_GET['s']).'%" or LOWER(version) LIKE "%'.strtolower($_GET['s']).'%")';

 $sql.=' order by cid desc limit '.(($n-1)*$on_page).','.$on_page;
	$r=mysql_query($sql);

	$x=($n-1)*100+1;
    while ($l=mysql_fetch_array($r))
	{
	echo $x++.'.'.stripslashes($l['name'])."\r\n".stripslashes($l['url'])."\r\n\r\n";
	if ($l['company']!='') echo stripslashes($l['company']);
	if ($l['version']!='') echo "/".stripslashes($l['version']);
	echo "\r\n\r\n";
	}

ob_end_flush();
?>