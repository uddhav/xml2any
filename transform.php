<?php 

$url = @$_REQUEST['url'];
$format = @$_REQUEST['format'];
$callback = @$_REQUEST['callback'];


$xp = new XsltProcessor();

$xsl = new DomDocument;

if ($format === "luax") {
	$xsl->load('xmltolua.xsl');
	header('Content-Type: text/plain; charset=UTF-8');	
} else if ($format === "lua") {
	$xsl->load('xmltolua-compact.xsl');
	header('Content-Type: text/plain; charset=UTF-8');
} else if ($format === "json") {
	$xsl->load('xmltojson-compact.xsl');
	header('Content-Type: application/json; charset=UTF-8');
} else if ($format === "jsonp") {
	$xsl->load('xmltojsonp-compact.xsl');
	header('Content-Type: application/javascript; charset=UTF-8');	
}

$xp->importStyleSheet($xsl);
$xp->setParameter('', 'decimalSupported', 'no');
	
if ($callback && $format === "jsonp")
	$xp->setParameter('', 'callback', $callback);

$xml = new DomDocument;

$contents = file_get_contents($url);

if ($contents) {
	$xml->loadXML($contents);
	
	if ($xform = $xp->transformToXML($xml)) {
		echo $xform;		
	} else {
		trigger_error('XSL transformation failed.', E_USER_ERROR);
	} 
} else {
	trigger_error('URL could not be loaded.', E_USER_ERROR);
}

?>