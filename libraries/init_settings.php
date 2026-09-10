<?php
define('DB_SETTINGS',[
   'host' => 'localhost',
   'port' => '3606',
   'user' => 'root',
   'pass' => '12345',
   'name' => 'gameshop',
]);

define('SUPPLIER_A',1);
define('SUPPLIER_B',2);
#вероятность отказа. Если событие отказа наступило, с равной вероятностью это может быть или падение (5хх) или таймаут, или таймаут при том, что код выдан
define('ERROR_PROBABILITY',[SUPPLIER_A => 70, SUPPLIER_B => 40]); #0..100, ключи это code_suppliers.id

$stmtCache = []; //$dbh->prepare statements cache, just in case