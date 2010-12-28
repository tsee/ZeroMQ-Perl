use strict;
use warnings;
use File::Spec;

use Test::More;
use ZeroMQ qw/:all/;
use Storable qw/nfreeze thaw/;

subtest 'connect before server socket is bound (should fail)' => sub {
    my $cxt = ZeroMQ::Context->new;
    my $sock = $cxt->socket(ZMQ_UPSTREAM); # Receiver

    # too early, server socket not created:
    my $client = $cxt->socket(ZMQ_DOWNSTREAM);
    eval { $client->connect("inproc://myPrivateSocket"); };
    ok($@ && "$@" =~ /Connection refused/);
};

subtest 'basic inproc communication' => sub {
    my $cxt = ZeroMQ::Context->new;
    my $sock = $cxt->socket(ZMQ_UPSTREAM); # Receiver
    eval {
        $sock->bind("inproc://myPrivateSocket");
    };
    ok !$@, "bind to inproc socket";

    my $client = $cxt->socket(ZMQ_DOWNSTREAM); # sender
    eval {
        $client->connect("inproc://myPrivateSocket");
    };
    ok !$@, "connect to inproc socket";

    ok(!defined($sock->recv(ZMQ_NOBLOCK)), "recv before sending anything should return nothing");
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
};


subtest 'invalid bind' => sub {
    my $cxt = ZeroMQ::Context->new(0); # must be 0 theads for in-process bind
    my $sock = $cxt->socket(ZMQ_REP); # server like reply socket
    eval {$sock->bind("bulls***");};
    ok($@ && "$@" =~ /Invalid argument/);
};

done_testing;
