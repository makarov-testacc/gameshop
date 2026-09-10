# Общие сведения

API выполнен на PHP, демон-выдавалка кодов - на Perl. Схема данных лежит в `exec_sql.sql` . При необходимости могу поднять это всё на удалённой машине в Интернете, сообщите если нужно.

На машине, где будет запускаться код, должен быть поднят сайт, в корне которого и должны лежать приложенные файлики. У меня сайт обозван `gameshop.loc` , если адрес будет другой - пропишите его в `daemons/get_code_d.pl` (константа `DOMAIN`) .

# Данные для коннекта к БД

1. Перл - `libraries/DB.pm`
```
our $Settings = {
  DSN => 'DBI:mysql:DB_NAME:DB_HOST:DB_PORT',
  user => 'USERNAME',
  pass => 'PASSWORD'
};
```
2. PHP - `libraries/init_settings.php`
```
define('DB_SETTINGS',[
   'host' => 'DB_HOST',
   'port' => 'DB_PORT',
   'user' => 'USERNAME',
   'pass' => 'PASSWORD',
   'name' => 'DB_NAME',
]);
```

# Вероятности отказа

Лежат в `libraries/init_settings.php`, константа `ERROR_PROBABILITY`.

# Порядок запуска

Сначала должен быть запущен демон-выдавалка кодов, `perl get_code_d.pl` (он вернёт управление в терминал, т.к. демон). Может ругаться на отсутствие модулей, вроде такого:

`Can't locate Some/Module.pm in @INC (you may need to install the Some::Module module)`

Тогда нужно сперва установить соответствующий модуль: `cpan install Some::Module`

Затем можно уже создавать заказ, оплачивать, демон будет их обрабатывать. Результат будет виден в БД.

# Масштабирование

Что касается обработчика заказов, сначала его можно распараллелить. Потом, если уж совсем разрастётся количество заказов - шардировать. Каждая шарда будет обрабатывать свои заказы (можно, например, брать заказы с условием `WHERE id MOD количество_шард = номер_шарды`).

# Примеры

Приводятся для хоста `gameshop.loc` .

- Создание заказа: `curl -k -X POST -H "Content-Type:application/x-www-form-urlencoded" -d 'sku=STEAM-TOPUP-500' https://gameshop.loc/create_order`
- Успешная оплата единичного заказа (order_id значение orders.id из базы): `curl -k -X POST -H "Content-Type:application/x-www-form-urlencoded" -d 'order_id=1&status=paid' https://gameshop.loc/payment`
- Неуспешная оплата единичного заказа (order_id значение orders.id из базы): `curl -k -X POST -H "Content-Type:application/x-www-form-urlencoded" -d 'order_id=1' https://gameshop.loc/payment`
- Параллельные уведомления о платеже можно сделать при помощи ApacheBench (ab): `ab -n 50 -c 50 -p /path/to/post_data.txt -T 'application/x-www-form-urlencoded' https://gameshop.loc/payment` При этом `/path/to/post_data.txt` должен содержать нечто вроде: `order_id=2&status=paid` (успешная оплата заказа с orders.id = 2) или `order_id=3` (неуспешная оплата заказа с orders.id = 3)
  **ВАЖНО**: post_data.txt не должен содержать перенос строки в конце. Для этого можно использовать PHP: `php -r 'file_put_contents("/path/to/post_data.txt","order_id=2&status=paid");'` или Perl: `perl -e 'open F,">/path/to/post_data.txt"; print F "order_id=2&status=paid"; close F;'`
  
# Время выполнения

В корне лежит соответствующий скриншот SVN лога. Несколько часов ушло, с учётом что у меня был простой самописный фреймворк.

# Что осталось непонятным

- Если мы отказались от поставщика А по таймауту, пошли просить код у поставщика Б, а поставщик А при этом успел выдать код, то нужна возможность отменить эту выдачу на его стороне. Иначе мы ж будем вынуждены заставлять клиента ждать.
- Из 4 этапа:
  > Эндпоинт скрипт сверки "оплачен, но не выдан" "выдан, но не оплачен"
  Не удалось мне понять, о чём это.
- 5 этап: Если там часто запрашиваемая страница, то в первую очередь надо кэширование разумное, дабы не дергать БД. Ну и не вполне понятно, что там должно выводиться и из каких таблиц. Оптимизировать-то запрос(ы) можно.
- В чём смысл request_id, если, как я понимаю, один ордер (заказ) - это один код? Посему, реализовано с учетом этого факта.

# Вопросы

ТГ `@oopsgeneralfailure`