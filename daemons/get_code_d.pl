#!/usr/bin/perl

use lib '../libraries';
use strict;
use POSIX;
use POSIX ":sys_wait_h";
use Common;
use DB;
use LWP::UserAgent;
use JSON::XS;
use HTTP::Request;
use URI::Escape;

use constant {
  DOMAIN    => 'gameshop.loc', #на этом хосте все поставщики живут (как и всё остальное). В PHP тоже используется (init_settings.php)
  MAX_TRIES => 10, #столько раз пытаемся выдать с увеличением интервала повтора, потом по новой с нуля начинаем
}; 

unless (Common::SetLock("get_code_d.lock")) {
  exit(0);
}

my $pid = fork();
exit() if $pid;
die "Couldn't fork: $! " unless defined($pid);
POSIX::setsid() or die "Couldn't start a new session $!";

my $time_to_die = 0;
sub signal_handler{
  Common::ReleaseLock();
  $time_to_die = 1;
}
$SIG{INT} = $SIG{TERM} = \&signal_handler;

sub REAPER {
  $SIG{CHLD} = \&REAPER;
  while ((my $waitedpid = waitpid(-1,WNOHANG)) > 0) { }
}

my $script = $0;
my $ua = new LWP::UserAgent;
$ua->timeout(5); #локально оно будет быстро отвечать поди, а если заглушка выдает таймаут (спит 10 сек) то мы как раз отвалимся, мол не шмогла
$ua->ssl_opts(verify_hostname => 0,SSL_verify_mode => 0x00);
$ua->agent('Code getter');

my @codeSuppliers;

DB::Connect();

#на всякий случай, при повторном пуске снова поставим в очередь заказы, зависшие в delivering - мало ли, всякое бывает
DB::Query('UPDATE orders SET status = "paid" WHERE status = "delivering"');
my $codeSuppliersSth = DB::Query('SELECT id,url FROM code_suppliers');
while (my ($id,$url) = $codeSuppliersSth->fetchrow()) {
  my $req = HTTP::Request->new(POST => 'https://' . DOMAIN . '/' . $url);
  $req->header('Content-Type' => 'application/x-www-form-urlencoded');
  push @codeSuppliers => {id => $id, req => $req};
}

until($time_to_die){
  #полезная нагрузка демона
  my @orders = map { $_->[0] } @{DB::Query('SELECT id FROM orders WHERE status = "paid" AND (next_check IS NULL OR next_check < NOW())')->fetchall_arrayref()};
  if (@orders) {
    #пометим, что мы взяли их в работу
    DB::Query('UPDATE orders SET status = "delivering" WHERE id IN (' . (join ',' => map {'?'} @orders) . ')',@orders);
    my $sth = DB::Query('SELECT o.id, o.tries, g.sku
      FROM orders o
      JOIN goods g ON g.id = o.good
      WHERE o.id IN (' . (join ',' => map {'?'} @orders) . ')',@orders);
    while (my ($order,$tries,$sku) = $sth->fetchrow()) {
      my $codeProvided = 0;
      foreach my $supplier (@codeSuppliers) {
        $0 = "$script working order $order on supplier " . $supplier->{id};
        # **WARN** если один поставщик ответил с таймаутом (мы не успели словить ответ), но при этом выдал код, то должна быть возможность отменить его на стороне поставщика
        # в ином случае мы вынуждены будем заставлять клиента ждать, когда же поставщик перестанет тупить (а если не ждать, то мы уже сделали fallback на другого поставщика)
        my $req = $supplier->{req};
        $req->content("order_id=" . URI::Escape::uri_escape($order) . '&sku=' . URI::Escape::uri_escape($sku));
        my $resp = $ua->request($req);
        if ($resp->is_success) {
          my $respObj;
          eval {
            $respObj = JSON::XS::decode_json($resp->decoded_content);
          };
          if ($@) { #че-то не жсонное нам ответили, хотя код 2хх, ну прологгируем это
            Common::Log("Order $order: non-json answer [URL " . $req->uri() . "], while response is successful. " . $resp->status_line . "\n" . $resp->content);
            next;
          }
          if ($respObj->{code}) {
            $codeProvided = 1;
            DB::Query('UPDATE orders SET status = "delivered", code = ?, supplier = ? WHERE id = ?',$respObj->{code},$supplier->{id},$order);
            last; #всё, код нам доставили, и норм, другого поставщика не смотрим
          } else {
            #WTF, нет кода в ожидаемом месте, хм, ну запишем это в лог хотя бы
            Common::Log("Order $order: no code in expected place [URL " . $req->uri() . "], while response is successful. " . $resp->status_line . "\n" . $resp->content);
          }
        }
      }
      
      unless ($codeProvided) { #не удалось получить код ни у одного поставщика
        #после 10 попыток снова идём по кругу, количество попыток только для увеличения интервала повторного запроса служит
        DB::Query('UPDATE orders
          SET tries = IF(tries < ?,?,0),
          next_check = NOW() + INTERVAL ? SECOND,
          status = "paid"
          WHERE id = ?'
          ,MAX_TRIES,++$tries
          ,2 ** $tries
          ,$order);        
      }
    }
  }
  $0 = "$script sleeping";
  sleep(5);
}
