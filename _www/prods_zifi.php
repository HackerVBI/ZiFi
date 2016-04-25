<?
  $image_folder='screens/';
  $files_folder='files/';

  include 'func.php';

  $db = dbconnect();
  session_start();
  ob_start();
  get_types();

  getpost_ifset(array('t'));

  // home directory - all prods
  $t = intval($t);
  $sql = "select * from prods where type = $t order by name";
  $r = mysql_query($sql);

$x=1;
$zifi_str='';
  while ($l = mysql_fetch_array($r))
  {
$zifi_str.=$x++.'.'.$l['name']."\r\n";
// echo $x++.'.'.$title."\r\n"   .$url."\r\n"    .$year."\r\n"   .$authors."\r\n".   $city."\r\n";
// echo $x++.'.'.$l['name']."\r\n"   .$url."\r\n\r\n"   .$authors."\r\n\r\n";

		$zifi_authors='';
    // group
    if ($l[group_id] != 0)
    {
      	$a = mysql_fetch_array(mysql_query("select name from groups where id = $l[group_id]"));
		$zifi_authors=stripslashes($a['name']).': ';
    }

    $c = mysql_query("select * from roles order by id");
    while ($b = mysql_fetch_array($c))
    {
      $q = mysql_query("
        select roles.name as role, authors.nick as author
        from credits
        inner join authors
        on credits.author_id = authors.id
        inner join roles
        on credits.role_id = roles.id
        where credits.prod_id = $l[id] and credits.role_id = $b[id]
        order by credits.role_id, lower(nick)
      ");


      while ($a = mysql_fetch_array($q)) $zifi_authors.=$a[author].', ';
    }
	$zifi_authors=substr ($zifi_authors,0,-2);

    // downloadable file
    if ($l['file_id'] != 0)
    {
      $a = mysql_fetch_array(mysql_query("select fname from files where id = $l[file_id]"));
      $zifi_str.='http://prods.tslabs.info/'.$files_folder.$a['fname'];
    } 
	  $zifi_str.="\r\n\r\n";
      $zifi_str.=$zifi_authors."\r\n\r\n";
  }
echo $zifi_str;
?>