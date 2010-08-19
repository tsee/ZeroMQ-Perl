use strict;
use warnings;
use Config;

use Time::HiRes qw/sleep time/;
use ZeroMQ qw/:all/;

BEGIN {
  if ( $Config{useithreads} ) {
    # We have threads
    require threads;
  }
  else {
    die 'Need threads to test ';
  }
}

if (@ARGV != 3) {
  die <<HERE;
usage: thread_0mq.pl <connect-to> <message-size> <roundtrip-count>
HERE
}

my $addr            = shift @ARGV;
my $msg_size        = shift @ARGV;
my $roundtrip_count = shift @ARGV;

my $local_thr = threads->create( \&local );

sub local {
  my $cxt = ZeroMQ::Context->new(1);
  my $sock = ZeroMQ::Socket->new( $cxt, ZMQ_REP );
  print "[local]  Trying to start at $addr \n";

  $sock->bind($addr);
  my $msg;
  foreach ( 1 .. $roundtrip_count ) {
    #warn "$_\n" if (not $_ % 1000);
    $msg = $sock->recv();
    die "Bad size" if $msg->size() != $msg_size;
    $sock->send($msg);
  }
}

sleep 0.1;
my $remote_thr = threads->create( \&remote );

sub remote {
  my $cxt = ZeroMQ::Context->new(1);
  my $sock = ZeroMQ::Socket->new( $cxt, ZMQ_REQ );

  print "[remote] Trying to start at $addr \n";
  $sock->connect($addr);
  my $text = '0' x $msg_size;
  my $msg  = ZeroMQ::Message->new($text);

  my $before = time();
  foreach ( 1 .. $roundtrip_count ) {
    #warn "$_\n" if (not $_ % 1000);
    $sock->send($msg);
    $msg = $sock->recv();
    die "Bad size" if $msg->size() != $msg_size;
  }
  my $after = time();
  my $latency = ($after - $before) / ( $roundtrip_count * 2 ) * 1.e6;
  print "Latency: $latency us\n";
}

END {
  $local_thr->join() if defined $local_thr;
  $remote_thr->join() if defined $remote_thr;
}
