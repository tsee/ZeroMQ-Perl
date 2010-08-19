use strict;
use warnings;
use ZeroMQ qw/:all/;
use Time::HiRes qw/time/;

if (@ARGV != 3) {
  die <<HERE;
usage: remote_lat <connect-to> <message-size> <roundtrip-count>
HERE
}

my $addr            = shift @ARGV;
my $msg_size        = shift @ARGV;
my $roundtrip_count = shift @ARGV;

my $cxt = ZeroMQ::Context->new(1);
my $sock = ZeroMQ::Socket->new($cxt, ZMQ_REQ);
$sock->connect($addr);

my $text = '0' x $msg_size;
my $msg = ZeroMQ::Message->new($text);

my $before = time();
foreach (1..$roundtrip_count) {
  #warn "$_\n" if (not $_ % 1000);
  $sock->send($msg);
  $msg = $sock->recv();
  die "Bad size" if $msg->size() != $msg_size;
}
my $after = time();
my $latency = ($after-$before) / ($roundtrip_count * 2) * 1.e6;

printf("message size: %d [B]\n", $msg_size);
printf("roundtrip count: %d\n", $roundtrip_count);
printf("average latency: %.3f [us]\n", $latency);


