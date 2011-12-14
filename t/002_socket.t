use strict;
use Test::More;
use Test::Fatal;

BEGIN {
    use_ok "ZeroMQ::Constants", qw(
        ZMQ_PUSH
        ZMQ_REP
        ZMQ_REQ
    );
    use_ok "ZeroMQ::Raw", qw(
        zmq_connect
        zmq_close
        zmq_init
        zmq_socket
        zmq_close
    );
}

subtest 'simple creation and destroy' => sub {
    is exception {
        my $context = zmq_init(1);
        my $socket  = zmq_socket( $context, ZMQ_REP );
        isa_ok $socket, "ZeroMQ::Raw::Socket";
    }, undef, "socket creation OK";

    is exception {
        my $context = zmq_init(1);
        my $socket  = zmq_socket( $context, ZMQ_REP );
        isa_ok $socket, "ZeroMQ::Raw::Socket";
        zmq_close( $socket );
    }, undef, "socket create, then zmq_close";

    is exception {
        my $context = zmq_init();
        my $socket  = zmq_socket( $context, ZMQ_REP );
        zmq_close( $socket );
        zmq_close( $socket );
    }, undef, "double zmq_close should not die";
};

subtest 'connect to a non-existent addr' => sub {
    is exception {
        my $context = zmq_init(1);
        my $socket  = zmq_socket( $context, ZMQ_PUSH );

        TODO: {
            todo_skip "I get 'Assertion failed: rc == 0 (zmq_connecter.cpp:46)'", 2;

        lives_ok {
            zmq_connect( $socket, "tcp://inmemory" );
        } "connect should succeed";

        zmq_close( $socket );
        dies_ok {
            zmq_connect( $socket, "tcp://inmemory" );
        } "connect should fail on a closed socket";

        }
    }, undef, "check for proper handling of closed socket";
};

done_testing;

__END__

SKIP : {
    eval { ZeroMQ::ZMQ_FD };
    skip "ZMQ_FD not available on this version: $@", 2 if $@;

    my $context = ZeroMQ::Context->new;
    my $socket = $context->socket(ZMQ_REP);
    $socket->bind("inproc://inmemory");
    my $client = $context->socket(ZMQ_REQ);
    $client->connect("inproc://inmemory");

    my $handle = $socket->getsockopt( ZeroMQ::ZMQ_FD );
    ok $handle;
    isa_ok $handle, "IO::Handle";

    $client->send("TEST");

    my $buf;
    sysread $handle, $buf, 4192, 0;
    warn $buf;
};
    

done_testing;