use strict;
use warnings;
use File::Spec;

use Test::More tests => 8;
use ZeroMQ qw/:all/;

pass();

{
  my $msg = ZeroMQ::Message->new("Hi there");
  isa_ok($msg, 'ZeroMQ::Message');
}
pass();

{
  my $cxt = ZeroMQ::Context->new(1);
  isa_ok($cxt, 'ZeroMQ::Context');
}
pass();


{
  my $cxt = ZeroMQ::Context->new(1);
  isa_ok($cxt, 'ZeroMQ::Context');
  my $sock = ZeroMQ::Socket->new($cxt, ZMQ_REQ); # "client" style request socket
  isa_ok($sock, 'ZeroMQ::Socket');
}
pass();
