use strict;
use warnings;
use ZeroMQ qw/:all/;

if (@ARGV != 3) {
  die <<HERE;
usage: local_lat <connect-to> <message-size> <roundtrip-count>
HERE
}

my $addr            = shift @ARGV;
my $msg_size        = shift @ARGV;
my $roundtrip_count = shift @ARGV;

my $cxt = ZeroMQ::Context->new(1);
my $sock = ZeroMQ::Socket->new($cxt, ZMQ_REP);
$sock->bind($addr);

my $msg;
foreach (1..$roundtrip_count) {
  #warn "$_\n" if (not $_ % 1000);
  $msg = $sock->recv();
  die "Bad size" if $msg->size() != $msg_size;
  $sock->send($msg);
}

sleep 1;

