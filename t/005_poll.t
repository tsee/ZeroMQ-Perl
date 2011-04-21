use strict;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok "ZeroMQ::Raw";
    use_ok "ZeroMQ::Constants", ":all";
}

subtest 'basic poll with fd' => sub {
    SKIP: {
        skip "Can't poll using fds on Windows", 2 if ($^O eq 'MSWin32');
        lives_ok {
            my $called = 0;
            zmq_poll([
                {
                    fd       => fileno(STDOUT),
                    events   => ZMQ_POLLOUT,
                    callback => sub { $called++ }
                }
            ], 1);
            ok $called, "callback called";
        } "PollItem doesn't die";
    }
};

subtest 'poll with zmq sockets' => sub {
    my $ctxt = zmq_init();
    my $req = zmq_socket( $ctxt, ZMQ_REQ );
    my $rep = zmq_socket( $ctxt, ZMQ_REP );
    my $called = 0;
    lives_ok {
        zmq_bind( $rep, "inproc://polltest");
        zmq_connect( $req, "inproc://polltest");
        zmq_send( $req, "Test");

        zmq_poll([
            {
                socket   => $rep,
                events   => ZMQ_POLLIN,
                callback => sub { $called++ }
            },
        ], 1);
    } "PollItem correctly handles callback";

    is $called, 1;
};

done_testing;