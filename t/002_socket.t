use strict;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok "ZeroMQ", qw(ZMQ_REP);
}

lives_ok {
    my $context = ZeroMQ::Context->new();
    my $socket  = $context->socket( ZMQ_REP );
} "sane allocation / cleanup for socket";

# Should probably run this test under valgrind to make sure
# we're not leaking memory

lives_ok {
    my $context = ZeroMQ::Context->new();
    my $socket  = $context->socket( ZMQ_REP );

    $socket->close();
    eval {
        $socket->connect("tcp://inmemory");
    };
} "check for proper handling of closed socket";
    

done_testing;