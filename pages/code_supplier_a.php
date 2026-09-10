<?php
if ($_SERVER['SCRIPT_NAME'] != '/disp.php') {
  header("HTTP/1.1 301 Moved Permanently");
  header("Location:/");
  exit();
}

if (!$_POST['order_id'] || !is_numeric($_POST['order_id'])) {
  $X->pd = ['status' => 'error', 'reason' => 'order_id is not provided or not numeric'];
  return;
}

#сюда приходят всеразличные параметры, но мы здесь будем просто выдавать код из имеющихся. При этом, если код уже выдан по заданному order_id, то отдавать будем вот его
SupplierAnswer($X,$_POST['order_id'],SUPPLIER_A);