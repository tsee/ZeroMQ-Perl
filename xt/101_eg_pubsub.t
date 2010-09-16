use strict;
use Test::More;
use Test::TCP;
BEGIN {
    use_ok "ZeroMQ", qw(ZMQ_PUB ZMQ_SUB ZMQ_SUBSCRIBE ZMQ_POLLIN ZMQ_NOBLOCK);
}

test_tcp(
    client => sub {
        my $port = shift;
        my $ctxt = ZeroMQ::Context->new();
        my $sock = $ctxt->socket(ZMQ_SUB);
        $sock->connect( "tcp://127.0.0.1:$port" );
        $sock->setsockopt(ZMQ_SUBSCRIBE, "W");
        my $message = $sock->recv;
        is $message->data, "WORLD?";
    },
    server => sub {
        my $port = shift;
        my $ctxt = ZeroMQ::Context->new();
        my $sock = $ctxt->socket(ZMQ_PUB);
        $sock->bind( "tcp://127.0.0.1:$port" );

        # if this server goes away before the client can recv(), the
        # client waits hanging
        local $SIG{ALRM} = sub {
            die "ZMQ_ALRM_TIMEOUT";
        };
        eval {
            alarm(10);
            my @message = qw(HELLO? WORLD? HELLO? HELLO?);
            while(1) {
                my $message = shift @message;
                if ($message) {
                    $sock->send($message);
                }
                sleep 1
            }
        };
    }
);

done_testing;