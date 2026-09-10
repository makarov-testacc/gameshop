<?php
if ($_SERVER['SCRIPT_NAME'] != '/disp.php') {
  header("HTTP/1.1 301 Moved Permanently");
  header("Location:/");
  exit();
}

if (!$_POST['order_id'] || !is_numeric($_POST['order_id'])) {
  $X->pd = ['result' => 'error', 'message' => 'No order_id provided or is not numeric'];
  return;
}
BeginTransaction($X);
$order = DBQuery('SELECT id,paid FROM orders WHERE id = ? FOR UPDATE',$_POST['order_id'])->fetchObject();
if (!$order->id) {
  RollBack($X);
  $X->pd = ['result' => 'error', 'message' => 'Order not found'];
  return;  
}

if ($order->paid) {
  RollBack($X);
  $X->pd = ['result' => 'ok']; #ну и скажем, что всё хорошо, обычно так делается в платежных системах, видимо это повторное уведомление
  return;
}

if ($_POST['status'] == 'paid') {
  DBQuery('UPDATE orders SET paid = NOW(), status = "paid" WHERE id = ?',$_POST['order_id']);
  #логгируем успешный платёж
  file_put_contents('payments.log',join("\t",[date("Y-m-d H:i:s"),"Payment notification on order " . $_POST['order_id'] . " received OK"]) . "\n",FILE_APPEND);
} else {
  DBQuery('UPDATE orders SET status = "payment_failed" WHERE id = ?',$_POST['order_id']);
}

Commit($X);

$X->pd = ['result' => 'ok'];