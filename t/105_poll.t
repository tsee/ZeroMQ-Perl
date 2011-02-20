use strict;
use warnings;

use Test::More;
use ZeroMQ qw/:all/;

use Devel::Refcount qw/refcount/;
use Devel::Cycle;

subtest 'PollItem poll with callbacks' => sub {
    my $ctxt = ZeroMQ::Context->new();
    my $rep = $ctxt->socket(ZMQ_REP);
    $rep->bind("inproc://polltest");
    my $req = $ctxt->socket(ZMQ_REQ);
    $req->connect("inproc://polltest");

    my $called = 0;
    my $poller = ZeroMQ::Poller->new(
        ZeroMQ::PollItem->new_from_hash(
            socket   => $rep,
            events   => ZMQ_POLLIN,
            callback => sub { $called++ }
        ),
    );

    $req->send("Test");
    $poller->poll(1);

    is $called, 1;
};

subtest 'PollItem poll with no callbacks' => sub {
    my $ctxt = ZeroMQ::Context->new();
    my $rep = $ctxt->socket(ZMQ_REP);
    $rep->bind("inproc://polltest");
    my $req = $ctxt->socket(ZMQ_REQ);
    $req->connect("inproc://polltest");

    my $poller = ZeroMQ::Poller->new(
        ZeroMQ::PollItem->new_from_hash(
            socket   => $rep,
            events   => ZMQ_POLLIN,
        ),
    );

    ok not $poller->has_event(0);

    $req->send("Test");
    $poller->poll(1);
    ok $poller->has_event(0);

    # repeat, to make sure event does not go away until picked up
    $poller->poll(1);
    ok $poller->has_event(0);

    $rep->recv();
    $poller->poll(1);
    ok not $poller->has_event(0);
};

subtest 'PollItem poll with names' => sub {
    my $ctxt = ZeroMQ::Context->new();
    my $rep = $ctxt->socket(ZMQ_REP);
    $rep->bind("inproc://polltest");
    my $req = $ctxt->socket(ZMQ_REQ);
    $req->connect("inproc://polltest");

    my $poller = ZeroMQ::Poller->new(
        test_item => ZeroMQ::PollItem->new_from_hash(
            socket   => $rep,
            events   => ZMQ_POLLIN,
        ),
    );

    ok not $poller->has_event('test_item');

    $req->send("Test");
    $poller->poll(1);
    ok $poller->has_event('test_item');

    # repeat, to make sure event does not go away until picked up
    $poller->poll(1);
    ok $poller->has_event('test_item');

    $rep->recv();
    $poller->poll(1);
    ok not $poller->has_event('test_item');
};
