use strict;
use warnings;
use File::Spec;

use Test::More tests => 25;
use ZeroMQ qw/:all/;
use Storable qw/nfreeze thaw/;

pass();

{
  my $msg = ZeroMQ::Message->new("Hi there");
  isa_ok($msg, 'ZeroMQ::Message');
}
pass();

{
  my $cxt = ZeroMQ::Context->new;
  isa_ok($cxt, 'ZeroMQ::Context');
}
pass();


{
  my $cxt = ZeroMQ::Context->new;
  isa_ok($cxt, 'ZeroMQ::Context');
  my $sock = $cxt->socket(ZMQ_UPSTREAM); # Receiver
  isa_ok($sock, 'ZeroMQ::Socket');

  { # too early, server socket not created:
    my $cxt = ZeroMQ::Context->new(1);
    my $client = $cxt->socket(ZMQ_DOWNSTREAM); # sender
    eval { $client->connect("inproc://myPrivateSocket"); };
    ok($@ && "$@" =~ /Connection refused/);
  }

  $sock->bind("inproc://myPrivateSocket");
  pass();

  my $client = $cxt->socket(ZMQ_DOWNSTREAM); # sender
  $client->connect("inproc://myPrivateSocket");
  pass("alive after connect");

  ok(!defined($sock->recv(ZMQ_NOBLOCK)));
  ok($client->send( ZeroMQ::Message->new("Talk to me") ));
  
  ok(!$sock->getsockopt(ZMQ_RCVMORE), "no ZMQ_RCVMORE set");
  ok($sock->getsockopt(ZMQ_AFFINITY) == 0, "no ZMQ_AFFINITY");
  ok($sock->getsockopt(ZMQ_RATE) == 100, "ZMQ_RATE is at default 100");

  my $msg = $sock->recv();
  ok(defined $msg, "received defined msg");
  is($msg->data, "Talk to me", "received correct message");

  # now test with objects, just for kicks.

  my $obj = {
    foo => 'bar',
    baz => [1..9],
    blah => 'blubb',
  };
  my $frozen = nfreeze($obj);
  ok($client->send( ZeroMQ::Message->new($frozen) ));
  $msg = $sock->recv();
  ok(defined $msg, "received defined msg");
  isa_ok($msg, 'ZeroMQ::Message');
  is($msg->data(), $frozen, "got back same data");
  my $robj = thaw($msg->data);
  is_deeply($robj, $obj);
}
pass();

{
  my $cxt = ZeroMQ::Context->new(0); # must be 0 theads for in-process bind
  my $sock = $cxt->socket(ZMQ_REP); # server like reply socket
  eval {$sock->bind("bulls***");};
  ok($@ && "$@" =~ /Invalid argument/);
}
pass();
