use strict;
use warnings;
use File::Spec;

use Test::More tests => 16;
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
  my $cxt = ZeroMQ::Context->new(1); # must be 0 theads for in-process bind
  isa_ok($cxt, 'ZeroMQ::Context');
  my $sock = ZeroMQ::Socket->new($cxt, ZMQ_UPSTREAM); # Receiver
  isa_ok($sock, 'ZeroMQ::Socket');

  { # too early, server socket not created:
    my $cxt = ZeroMQ::Context->new(0); # must be 0 theads for in-process bind
    my $client = ZeroMQ::Socket->new($cxt, ZMQ_DOWNSTREAM); # sender
    eval { $client->connect("inproc://myPrivateSocket"); };
    ok($@ && "$@" =~ /Connection refused/);
  }

  $sock->bind("inproc://myPrivateSocket");
  pass();

  my $client = ZeroMQ::Socket->new($cxt, ZMQ_DOWNSTREAM); # sender
  $client->connect("inproc://myPrivateSocket");
  pass("alive after connect");

  ok(!defined($sock->recv(ZMQ_NOBLOCK)));
  ok($client->send( ZeroMQ::Message->new("Talk to me") ));
  
  # FIXME find otu why these are throwing exceptions...
  #ok(!$sock->getsockopt(ZMQ_RCVMORE), "no ZMQ_RCVMORE set");
  #ok($sock->getsockopt(ZMQ_AFFINITY) == 0, "no ZMQ_AFFINITY");
  #ok($sock->getsockopt(ZMQ_RATE) == 100, "ZMQ_RATE is at default 100");

  my $msg = $sock->recv();
  ok(defined $msg, "received defined msg");
}
pass();

{
  my $cxt = ZeroMQ::Context->new(0); # must be 0 theads for in-process bind
  my $sock = ZeroMQ::Socket->new($cxt, ZMQ_REP); # server like reply socket
  eval {$sock->bind("bulls***");};
  ok($@ && "$@" =~ /Invalid argument/);
}
pass();
