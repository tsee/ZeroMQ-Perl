use strict;
use Test::More;
use Test::Exception;
BEGIN {
    use_ok "ZeroMQ", "ZMQ_REP", "ZMQ_REQ", "ZMQ_POLLIN", "ZMQ_POLLOUT", "ZMQ_NOBLOCK";
}

lives_ok {
    my $ctxt = ZeroMQ::Context->new;
    my $sock = $ctxt->socket( ZMQ_REP );
    my $item = ZeroMQ::PollItem->new();
    ok $item;
    isa_ok $item, 'ZeroMQ::PollItem';
    {
        my $guard = $item->add( $sock, ZMQ_POLLIN, sub { ok "callback" } );
        is($item->size, 1);
    }
    is($item->size, 0);
} "PollItem doesn't die";

lives_ok {
    my $ctxt = ZeroMQ::Context->new;
    my $req = $ctxt->socket( ZMQ_REQ );
    my $rep = $ctxt->socket( ZMQ_REP );
    my $callback = 0;
    
    my $pi  = ZeroMQ::PollItem->new();
    {
        $rep->bind("inproc://polltest");
        $req->connect("inproc://polltest");
        $req->send("Test");

        my $guard; $guard = $pi->add( $rep, ZMQ_POLLIN, sub { 
            $callback++;
            undef $guard;
        } );

        $pi->poll(0);
    }

    is $callback, 1;
} "PollItem correctly handles callback";

done_testing;