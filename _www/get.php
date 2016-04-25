<?php

date_default_timezone_set('Etc/GMT-3');

error_reporting(E_ERROR);

header('Content-type: text/plain');

if (stristr($_SERVER['HTTP_HOST'], '.local')) {
	require_once('/persistent/FirePHPCore/fb.php');
}

switch (isset($_GET['src']) ? $_GET['src'] : false) {
	case 'hype':
		displayHypeUpdates();
		break;
	case 'hype_topic':
		displayHypeTopic(isset($_GET['id']) ? $_GET['id'] : false);
		break;
	default:
		error('Wrong request', __FILE__, __LINE__);
}

function displayHypeUpdates() {
	if (!$xml = simplexml_load_string(file_get_contents('http://hype.retroscene.org/rss/'))) {
		error('Unable to load source content', __FILE__, __LINE__);
	}	
	
	if (!$xml->channel->item) {
		$error('Wrong source format.', __FILE__, __LINE__);
	}

	$ns = $xml->getNamespaces(true);
	
	ob_start();
	foreach ($xml->channel->item as $i) {
		preg_match('/\/(\d*)\./', $i->link, $matches);
		$url = 'http://ts.retropc.ru/get.php?src=hype_topic&id='.$matches[1];
		
		echo iconv('utf-8', 'cp866//TRANSLIT', $i->title)."\r\n";
		echo $url."\r\n";
		echo date('d.m.Y', strtotime($i->pubDate))."\r\n";
		echo iconv('utf-8', 'cp866//TRANSLIT', $i->children($ns['dc'])->creator)."\r\n";
		echo "\r\n";
	}
	
	exit (ob_get_clean());
}

function displayHypeTopic($id) {
	if (!$src = @file_get_contents('http://hype.retroscene.org/blog/'.intval($id).'.html')) {
		error('Unable to load source', __FILE__, __LINE__);
	}

	if (preg_match('/<h1 class="topic-title word-wrap">(.*)<\/h1>/s', $src, $matches)) {
		$title = trim(strip_tags($matches[1]));
	}
	else {
		$title = '';		
	}
	
	if (preg_match('/<a.*rel="author".*>(.*)<\/a>/', $src, $matches)) {
		$author = trim(strip_tags($matches[1]));
	}
	else {
		$author = '';	
	}

	if (preg_match_all('/<li class="topic-info-date">\s*<time.*title="(.*)"/', $src, $matches)) {
		$posted = trim(strip_tags($matches[1][0]));
	}
	else {
		$posted = '';
	}
	
	$text = "\r\n";
	if (preg_match_all('/<div class="topic-content text">(.*)<footer class="topic-footer">/s', $src, $matches)) {
		foreach (explode("\n\r", strip_tags($matches[1][0])) as $line) {
			$text .= trim($line)."\r\n\r\n";
		}
	}
	
	echo iconv('utf-8', 'cp866//TRANSLIT', $title)."\r\n";
	echo iconv('utf-8', 'cp866//TRANSLIT', $author)."\r\n";
	echo iconv('utf-8', 'cp866//TRANSLIT', $posted)."\r\n";
	echo iconv('utf-8', 'cp866//TRANSLIT', $text);
	exit;
}

function error($message, $file, $line) {
	if (class_exists('FB')) {
		FB::setOptions(array('includeLineNumbers' => false));
		FB::group('Error: '.$message,array('Collapsed' => true,'Color' => '#FF0000'));
		FB::info($file, 'File');
		FB::info($line, 'Line');
		FB::groupEnd();
	}
	
	exit($message);
}
