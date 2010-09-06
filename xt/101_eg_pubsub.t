use strict;
use Test::More;
use Test::TCP;
BEGIN {
    use_ok "ZeroMQ", qw(ZMQ_PUB ZMQ_SUB ZMQ_SUBSCRIBE ZMQ_POLLIN ZMQ_NOBLOCK);
}

TODO: {
    todo_skip "This test still fails for me :/", 1;

test_tcp(
    client => sub {
        my $port = shift;
        my $ctxt = ZeroMQ::Context->new();
        my $sock = $ctxt->socket(ZMQ_SUB);
        $sock->connect( "tcp://127.0.0.1:$port" );
        $sock->setsockopt(ZMQ_SUBSCRIBE, "W");

        local $SIG{ALRM} = sub {
            die "ZMQ_ALRM_TIMEOUT";
        };
        eval {
            alarm(10);

            my $pollitem = ZeroMQ::PollItem->new();
            $pollitem->add($sock, ZMQ_POLLIN, sub {
                my $message = $sock->recv(ZMQ_NOBLOCK);
                is $message->data, "WORLD?";
            });
            while (1) {
                $pollitem->poll();
                sleep 1;
            }
            alarm(0);
        };
        if (my $e = $@) {
            if ($e =~ /ZMQ_ALRM_TIMEOUT/) {
                $sock->close;
                fail("Timeout");
            }
        }
    },
    server => sub {
        my $port = shift;
        my $ctxt = ZeroMQ::Context->new();
        my $sock = $ctxt->socket(ZMQ_PUB);
        $sock->bind( "tcp://127.0.0.1:$port" );

        $sock->send("WORLD?");
        $sock->send("HELLO?");
        $sock->send("HELLO?");
        $sock->send("HELLO?");
        # if this server goes away before the client can recv(), the
        # client waits hanging
        local $SIG{ALRM} = sub {
            die "ZMQ_ALRM_TIMEOUT";
        };
        eval {
            alarm(10);
            while(1) { sleep 1 }
        };
    }
);

}

done_testing;