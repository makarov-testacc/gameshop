<?php
error_reporting(E_PARSE | E_ERROR | E_WARNING | E_DEPRECATED | E_CORE_ERROR | E_COMPILE_ERROR);
#поскольку мы, для простоты, будем на ходу создавать свойства в объектах stdClass, то подавим вот некоторые ошибки
set_error_handler(function($errno,$errstr) {
  if (
    (strpos($errstr, 'Undefined array key') === false) &&
    (strpos($errstr, 'Undefined variable') === false) &&
    (strpos($errstr, 'Undefined property') === false) &&
    (strpos($errstr, 'Trying to access array offset on value of type') === false) # if ($row['some'] для случая когда $row это FALSE (нет записи в базе)) или if ($a['k']['a']['b'] когда $a['k'] нет вообще)
  ) {
    return false; #pass to std err handler
  } else {
    return true;
  }
}, E_WARNING);

require_once("libraries/init_settings.php");
require_once("libraries/allowed_pages.php");

$X = new stdClass;

$X->pd 		    = new stdClass(); // pagedata
$X->pd->pager	= new stdClass(); // pager

$X->dbh 	    = false;

require_once("libraries/common.lib.php");
$X->urlParams = $_GET['q'] ? explode("/",$_GET['q']) : ['homepage'];
if (ALLOWED_PAGES[$X->urlParams[0]] && ALLOWED_PAGES[$X->urlParams[0]]['libs']) {
  if (!is_array(ALLOWED_PAGES[$X->urlParams[0]]['libs']))
    die("libs shd be an array");
  foreach (ALLOWED_PAGES[$X->urlParams[0]]['libs'] as $lib) {
    require_once("libraries/$lib.lib.php");
  }
}
if ($_GET['asjson']) {
  $X->needJSON = true;
}

if (array_key_exists($X->urlParams[0],ALLOWED_PAGES)) {
  DBConnect($X);
  require_once("pages/" . $X->urlParams[0] . ".php");
  if ($X->http_code)
    header($X->http_code);
  header("Content-Type:application/json;charset=utf-8");
  print $X->needJSON ? asjson($X) : asjson($X->pd);
  exit;
} else {
  die("No page for " . $X->urlParams[0]);
}
