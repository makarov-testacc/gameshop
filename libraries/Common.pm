package Common;
use Fcntl qw(:flock);
use JSON::XS;

my $PidFile;

sub SetLock{
  $PidFile = shift;
  unless ($PidFile){
    $0 =~ /^(.*?\/)?([^\/]+?)(\.[^\.]+)?$/;
    my $f = $2 || $$;
    $PidFile = "$f.lock";
  }
  open FLOCKPIDFILE,">$PidFile" or die "$!";
  unless (flock FLOCKPIDFILE, LOCK_EX | LOCK_NB){
    close FLOCKPIDFILE;
    my $whoLocked = (stat $PidFile)[4];
    die "[ERR] '$PidFile' locked by another user: uid=$whoLocked login=".getpwuid($whoLocked) if ($< != $whoLocked);
    return;
  }
  return 1;
}

sub ReleaseLock{
  flock(FLOCKPIDFILE, LOCK_UN);
  close FLOCKPIDFILE;
  unlink $PidFile;
  return 1;
}

sub Log {
  my $text = shift || return;
  open my $LOG,">>./failure.log";
  binmode $LOG;
  print $LOG localtime() . "\t$text\n";
  close $LOG;
}


1;
