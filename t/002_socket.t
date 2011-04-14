use strict;
use Test::More;
use Test::Exception;

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
    );
}

subtest 'simple creation and destroy' => sub {
    lives_ok {
        my $context = zmq_init(1);
        my $socket  = zmq_socket( $context, ZMQ_REP );
        isa_ok $socket, "ZeroMQ::Raw::Socket";
    } "code lives";

    lives_ok {
        my $context = zmq_init(1);
        my $socket  = zmq_socket( $context, ZMQ_REP );
        isa_ok $socket, "ZeroMQ::Raw::Socket";
        zmq_close( $socket );
    } "code lives";
};

subtest 'connect to a non-existent addr' => sub {
    lives_ok {
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
    } "check for proper handling of closed socket";
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