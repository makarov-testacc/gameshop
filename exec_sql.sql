CREATE TABLE goods (
  id INT(10) UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  sku VARCHAR(50) NOT NULL,
  goodname VARCHAR(100) NOT NULL,
  goodtype ENUM('topup','key','subscription','giftcard') DEFAULT 'key',
  price SMALLINT UNSIGNED NOT NULL,
  image VARCHAR(20) DEFAULT NULL,
  UNIQUE KEY (sku)
);
INSERT INTO goods(sku,goodname,goodtype,price,image)
VALUES
("STEAM-TOPUP-500","Пополнение Steam 500 ₽","topup",500,'steam'),
("STEAM-TOPUP-1000","Пополнение Steam 1000 ₽","topup",1000,'steam'),
("STEAM-TOPUP-2500","Пополнение Steam 2500 ₽","topup",2500,'steam'),
("KEY-CS2-PRIME","CS2 Prime Status ключ","key",1290,'cs2'),
("KEY-GTA5","GTA V ключ активации","key",1990,'gta5'),
("KEY-EFT","Escape from Tarkov ключ","key",3490,'eft'),
("SUB-DISCORD-1M","Discord Nitro 1 месяц","subscription",399,'discord'),
("SUB-YT-3M","YouTube Premium 3 месяца","subscription",1490,'youtube'),
("SUB-SPOTIFY-1M","Spotify Premium 1 месяц","subscription",299,'spotify'),
("GIFT-PSN-1000","PlayStation Store карта 1000 ₽","giftcard",1000,'psn'),
("GIFT-XBOX-1500","Xbox Gift Card 1500 ₽","giftcard",1500,'xbox'),
("GIFT-ROBLOX-800","Roblox 800 Robux","giftcard",890,'roblox');
CREATE TABLE code_suppliers(
  id TINYINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL,
  url VARCHAR(30) NOT NULL COMMENT 'для простоты пока урл пропишем, куда ломиться'
);
INSERT INTO code_suppliers(id,name,url) VALUES (1,'Поставщик А','code_supplier_a'),(2,'Поставщик Б','code_supplier_b');
CREATE TABLE orders(
  id INT(10) UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  good INT(10) UNSIGNED NOT NULL COMMENT 'ID товара, внешний ключ не будем уж прописывать',
  dt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  paid DATETIME DEFAULT NULL,
  supplier TINYINT UNSIGNED DEFAULT NULL COMMENT 'ID поставщика, также внешний ключ не будем прописывать',
  code VARCHAR(20) DEFAULT NULL,
  `status` ENUM('created','paid','delivering','delivered','payment_failed','out_of_stock','delivery_failed') NOT NULL DEFAULT 'created',
  tries TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Сколько попыток уже было',
  next_check DATETIME DEFAULT NULL COMMENT 'Когда следующий раз пробуем получить код',
  UNIQUE KEY (code),
  KEY (status,next_check)
);

CREATE TABLE code_suppliers_orders(
  supplier TINYINT UNSIGNED NOT NULL COMMENT 'Из таблицы code_suppliers',
  `order_id` INT(10) UNSIGNED NOT NULL COMMENT 'Из таблицы orders',
  `code` VARCHAR(20) NOT NULL,
  PRIMARY KEY (supplier,`order_id`)
) COMMENT 'Здесь будем хранить уже выданные по заданным ордерам коды, это для работы наших заглушек-поставщиков';

-- для простоты будем полагать, что на любой SKU поставщику можно выдать любой невыданный код, то есть не будет таблицы goods_codes, которая бы этот момент ограничивала
CREATE TABLE codes(
  id INT(10) UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  code VARCHAR(30) NOT NULL DEFAULT '',
  UNIQUE (code)
);

INSERT INTO codes(code)
VALUES
("LFXC-TNCS-BPCD"),
("P3EI-W8UO-9B4K"),
("FEL3-GUXN-TCCH"),
("YPLV-QK2Z-IUS5"),
("0K9E-P1FR-BY1U"),
("5LZV-UQ48-RXCZ"),
("X93K-NYAQ-GEC1"),
("EIO5-CQT5-35KO"),
("M58F-GIIR-VJAP"),
("NU8Y-SWYB-6252"),
("OODW-CCHF-MBAF"),
("DNA5-WFJM-NE49"),
("QRDD-MJ3F-A8TF"),
("TAT9-5ZJN-G1T2"),
("LI39-4330-ISMB"),
("BKJY-8Q79-8NHI"),
("HHW6-4RX2-DX62"),
("1RG2-L28O-O80G"),
("EF63-F39X-MTEA"),
("8XS7-P53H-JKIV"),
("JPE6-MQV6-P7ST"),
("SAPG-A2GR-0ULS"),
("T2DU-IJ1S-U16P"),
("WSSY-QTR7-Z57J"),
("U74E-EPCI-CY26"),
("FZXF-58H8-OR93"),
("FPSM-HLZA-TPAL"),
("WSC9-28DJ-B2JE"),
("P63J-F7UZ-DCYP"),
("C7W2-D4C5-QMT7"),
("JESI-DFBH-LK1K"),
("SGMA-JA0T-GR7D"),
("3PR4-OSY9-M3ZW"),
("OMBE-C0JF-D45Y"),
("KIKQ-FQJ8-9TI8"),
("LMAN-RSHS-AJDO"),
("BAKI-VT1X-Z5OL"),
("9F0X-B46W-03FS"),
("S423-V6YY-IBEM"),
("D4UW-WYRA-20ST"),
("XC0J-CJ0H-09RN"),
("RY1W-XCFJ-0KUA"),
("CJYY-YKSQ-QE6H"),
("97AQ-38QJ-H8HU"),
("FS8E-3S5Z-I6RA"),
("ARQK-FML4-A14E"),
("7Z6K-NO9V-MPJB"),
("D4K7-IJSG-N853"),
("W67T-ZB0Q-1XKB"),
("7EQM-K09J-XKUO");