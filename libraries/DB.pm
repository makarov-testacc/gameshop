package DB;

use DBI;

our $Settings = {
  DSN => 'DBI:mysql:gameshop:localhost:3306',
  user => 'root',
  pass => '12345'
};

my $stmtCache = {};
my $dbHandle;

sub Connect {
  $dbHandle = DBI->connect($Settings->{DSN}, $Settings->{user}, $Settings->{pass}, { RaiseError => 0, PrintError => 0, mysql_auto_reconnect => 1, mysql_enable_utf8 => 1  });
  die DBI->errstr() unless $dbHandle;
}

sub Query {
  my $sql = shift;
  my @sqlParams = @_;
  my $sth;
  if (exists $stmtCache->{$sql}) {
    $sth = $stmtCache->{$sql};
  } else {
    $sth = $dbHandle->prepare($sql);
    $stmtCache->{$sql} = $sth if $sth;
  }
  my $res = $sth->execute(@sqlParams);
  unless ($res) {
    die "ERROR in query\n$sql\n\nERROR: " . $sth->errstr;
  }
  return $sth;
}


1;