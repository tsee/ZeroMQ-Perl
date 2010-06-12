use strict;
use warnings;
use File::Spec;

use Test::More tests => 13;
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
  my $cxt = ZeroMQ::Context->new(0); # must be 0 theads for in-process bind
  isa_ok($cxt, 'ZeroMQ::Context');
  my $sock = ZeroMQ::Socket->new($cxt, ZMQ_REP); # server like reply socket
  isa_ok($sock, 'ZeroMQ::Socket');

  { # too early, server socket not created:
    my $client = ZeroMQ::Socket->new($cxt, ZMQ_REQ); # "client" style request socket
    eval { $client->connect("inproc://myPrivateSocket"); };
    ok($@ && "$@" =~ /Connection refused/);
  }

  $sock->bind("inproc://myPrivateSocket");
  pass();

  my $client = ZeroMQ::Socket->new($cxt, ZMQ_REQ); # "client" style request socket
  $client->connect("inproc://myPrivateSocket");
  pass();

}
pass();

{
  my $cxt = ZeroMQ::Context->new(0); # must be 0 theads for in-process bind
  my $sock = ZeroMQ::Socket->new($cxt, ZMQ_REP); # server like reply socket
  eval {$sock->bind("bulls***");};
  ok($@ && "$@" =~ /Invalid argument/);
}
pass();
