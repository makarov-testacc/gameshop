<?php
function getPlaceholders($array) {
	return join(",",array_map(function($el) { return "?"; },$array));
}
function asjson($object) {
	return json_encode($object,JSON_PARTIAL_OUTPUT_ON_ERROR);
}

function DBQuery($sql,$sqlParams = null) {
	global $X,$stmtCache;
	$args = func_get_args();
	$sql = array_shift($args);

	$sqlMd5 = md5($sql);

  if (!$X->dbh)
    DBConnect($X);

	if ($stmtCache[$sqlMd5]) {
		$sth = $stmtCache[$sqlMd5];
	} else {
    $sth = $X->dbh->prepare($sql);
		if ($sth) {
			$stmtCache[$sqlMd5] = $sth;
		} else {
			$errStr = "ERROR on prepare sql $sql: " . print_r($X->dbh->errorInfo(),true);
			file_put_contents('dbquery_fail.log',join("\t",[date("Y-m-d H:i:s"),$errStr]) . "\n",FILE_APPEND);
			die($errStr);
		}
	}

  if (is_array($args[0])) {
    $sth->execute((array)$args[0]);
  } else {
    $sth->execute($args);
  }

	return $sth;
}

function DBConnect($X) {
	try {
		$X->dbh = new PDO("mysql:host=" . DB_SETTINGS['host'] . ";port=" . DB_SETTINGS['port'] . ";dbname=" . DB_SETTINGS['name'] . ";charset=utf8mb4",
			DB_SETTINGS['user'], DB_SETTINGS['pass'],
			[
				PDO::ATTR_ERRMODE 						=> PDO::ERRMODE_SILENT,
				PDO::ATTR_DEFAULT_FETCH_MODE 	=> PDO::FETCH_ASSOC,
				PDO::ATTR_EMULATE_PREPARES 		=> false
			]
		);
	} catch(PDOException $e) {
		die("Error connecting to DB " . $e->getMessage());
	}
}

function LastInsertId($X) {
  return $X->dbh->lastInsertId();
}

function BeginTransaction($X) {
  return $X->dbh->beginTransaction();
}

function Commit($X) {
  return $X->dbh->commit();
}

function RollBack($X) {
  return $X->dbh->rollBack();
}

function SupplierAnswer($X,$order,$supplier = SUPPLIER_A) {
  $failRand = 0;
  if (ERROR_PROBABILITY[$supplier] && rand(1,100) < ERROR_PROBABILITY[$supplier]) { #о, надо потупить
    $failRand = rand(1,99); #sic, чтобы ровно треть вероятности можно было выделить
    if ( $failRand >= 1 && $failRand <= 33 ) {
      sleep(10);
    } elseif ( $failRand > 33 && $failRand <= 66 ) {
      $X->http_code = "HTTP/1.1 500 Internal Server Error";
      return;
    }
  }
  BeginTransaction($X);
  #полагаем, что выданный код у нас хранится в табличке code_suppliers_orders. На деле поставщик хранит его где-то там у себя, разумеется  
  #посмотрим, может мы уже выдали код
  $suppOrder = DBQuery('SELECT order_id, code FROM code_suppliers_orders WHERE order_id = ? AND supplier = ? FOR UPDATE',$order,$supplier)->fetchObject();
  if ($suppOrder->code) {
    RollBack($X);
    $X->pd = ['status' => 'ok', 'order_id' => $suppOrder->order_id, 'code' => $suppOrder->code];
    return;
  }
  
  #код еще не выдавали, ну ок
  $codeObj = DBQuery('SELECT code FROM codes LIMIT 1 FOR UPDATE')->fetchObject();
  if (!$codeObj) { #блин, коды закончились
    $X->http_code = "HTTP/1.1 404 Not Found";
    $X->pd = ['status' => 'error', 'reason' => 'out_of_stock'];
    return;
  }
  
  DBQuery('INSERT INTO code_suppliers_orders(order_id,supplier,code) VALUES (?,?,?)',$order,$supplier,$codeObj->code);
  DBQuery('DELETE FROM codes WHERE code = ?',$codeObj->code);
  Commit($X);
  if ($failRand > 66) { #код выдали, время потупить
    sleep(10);
  }
  $X->pd = ['status' => 'ok', 'order_id' => $order, 'code' => $codeObj->code];
}