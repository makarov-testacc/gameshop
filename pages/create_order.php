<?php
if ($_SERVER['SCRIPT_NAME'] != '/disp.php') {
  header("HTTP/1.1 301 Moved Permanently");
  header("Location:/");
  exit();
}
if (!$_POST['sku']) {
  $X->pd = ['result' => 'error', 'message' => 'No SKU provided'];
  return;
}

$good = DBQuery('SELECT id FROM goods WHERE sku = ?',$_POST['sku'])->fetchObject();
if (!$good->id) {
  $X->pd = ['result' => 'error', 'message' => 'SKU not found'];
  return;  
}

DBQuery('INSERT INTO orders(good) VALUES (?)',$good->id);
$orderID = LastInsertId($X);

$X->pd = ['result' => 'ok', 'order' => $orderID];