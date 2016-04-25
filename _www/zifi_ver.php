<?
define('CRC16POLYN', 0x1021);
$dir='zifi_current/';
$cur_ver='065';

  $db=mysql_connect("localhost", "ts", "L4CDHC9j5UwnVZQ2") or die ("Could not connect to MySQL server!");
  mysql_select_db("ts",$db);
	mysql_query('SET NAMES utf8;');

/*
mysql_query("drop table zifi_updates");
echo mysql_error();

$sql='create table zifi_updates (
  version varchar(4) not null, 
  upd_version bool not null, 
  zifi_type varchar(4) not null, 
  date datetime not null, 
  ip varchar(16) not null, 
  cid int4 not null auto_increment,
  PRIMARY KEY (cid)
)';
 
$result = mysql_query($sql);
if ($result==1) echo ' zifi_updates ';

echo mysql_error();
exit;
*/

if (isset($_GET['c']))
 if ($_GET['c'] ==$cur_ver) 
  { 
   updated(0,$cur_ver,"RS");
   echo "Your spg is up to date.";
   exit;
   
  } else  {
   updated(1,$_GET['c'],"RS");
   echo strtoupper(dechex(CRC16Normal(file_get_contents($dir."zifi_rs.spg"))));
   readfile($dir."zifi_rs.spg");
   exit;
  }

if (isset($_GET['w']))
 if ($_GET['w'] ==$cur_ver) 
  { 
   updated(0,$cur_ver,"ESP");
   echo "Your spg is up to date.";
   exit;
   
  } else   {
   updated(1,$_GET['w'],"ESP");
   echo strtoupper(dechex(CRC16Normal(file_get_contents($dir."zifi.spg"))));
   readfile($dir."zifi.spg");
   exit;
  }


// echo dechex(CRC16Normal(file_get_contents("zifi.bin")));
function updated($is_updated,$version,$type)
{
	$sql='insert into zifi_updates (zifi_type,version,upd_version,date,ip) values 
    	("'.$type.'","'.$version.'",'.$is_updated.', "'.date("Y-m-d H:i:s").'", "'.ip().'")';
  mysql_query ($sql);
//  echo $sql;
// echo mysql_error();
}

function CRC16Normal($buffer) {
    $result = 0xFFFF;
    if (($length = strlen($buffer)) > 0) {
        for ($offset = 0; $offset < $length; $offset++) {
            $result ^= (ord($buffer[$offset]) << 8);
            for ($bitwise = 0; $bitwise < 8; $bitwise++) {
                if (($result <<= 1) & 0x10000) $result ^= CRC16POLYN;
                $result &= 0xFFFF;
            }
        }
    }
    return $result;
}

function ip()
{
 if (empty($REMOTE_ADDR))
    if(isset($_SERVER['HTTP_X_FORWARDED_FOR'])) $REMOTE_ADDR=$_SERVER['HTTP_X_FORWARDED_FOR'];
    else $REMOTE_ADDR=$_SERVER['REMOTE_ADDR'];

    return trim($REMOTE_ADDR);
}

/*
$r=mysql_query ('select * from zifi_updates order by cid desc');
 while ($l = mysql_fetch_array($r)) echo $l['version'].', '.$l['upd_version'].', '.$l['zifi_type'].', '.$l['date'].', '.$l['ip'].'<br>';
exit;
*/


// $max=mysql_fetch_array(mysql_query ('select max(cid) as cnt from zifi_updates group by date limit 1'));
$r=mysql_query ('select count(cid) as cnt, DATE_FORMAT(date, "%e.%c.%Y") as dat from zifi_updates group by dat order by cid');
?>
<html>
  <head>
  <title>Zifi on the air! Stats</title>
<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">
      google.charts.load('current', {'packages':['corechart']});
      google.charts.setOnLoadCallback(drawChart);
      function drawChart() {
        var data = google.visualization.arrayToDataTable([
          ['Day', 'Count'],
<?
 $str='';
 while ($l = mysql_fetch_array($r)) $str.='["'.$l['dat'].'", '.$l['cnt'].'],';
 echo substr($str,0,-1);
?>
        ]);
		var options = {
          title: 'Stats: Zifi on the air by date. Current version: <? echo $cur_ver[0].'.'.$cur_ver[1].$cur_ver[2]; ?>',
          curveType: 'function',
          legend: { position: 'bottom' }
        };

       var chart = new google.visualization.LineChart(document.getElementById('curve_chart'));
       chart.draw(data, options);
      }
    </script>
  </head>
  <body bgcolor="#666666">
<div align=center >
 <div style="box-shadow:0px 00px 20px 20px #555; width:640px">
 <img src=logo.png >
    <div id="curve_chart" style="width: 640px; height: 500px;"></div>
 </div>
</div>
  </body>
</html>