BEGIN {
     require Config;
     if (!$Config::Config{useithreads}) {
        print "1..0 # Skip: no ithreads\n";
        exit 0;
     }
}

use strict;

# XXX use Test::More before use threads to fool Test::More, which
# doesn't play nicely with Test::SharedFork
use Test::More;
use threads;
use Test::Requires 'Test::TCP';

BEGIN {
    use_ok "ZeroMQ", qw(ZMQ_REQ ZMQ_XREQ ZMQ_XREP ZMQ_REQ ZMQ_REP ZMQ_QUEUE);
}

test_tcp( 
    client => sub {
        my $port = shift;
        my $ctxt = ZeroMQ::Context->new();
        my $sock = $ctxt->socket(ZMQ_REQ);
        $sock->connect( "tcp://127.0.0.1:$port" );
        for (1..10) {
            $sock->send("Hello $$");
            my $message = $sock->recv();
        }
        $sock->send("END") for 1..5;
    },
    server => sub {
        my $port = shift;
        my $ctxt = ZeroMQ::Context->new();
        my $clients = $ctxt->socket(ZMQ_XREP);
        my $workers = $ctxt->socket(ZMQ_XREQ);

        $clients->bind( "tcp://127.0.0.1:$port" );
        $workers->bind( "inproc://workers" );

        my @threads;
        for (1..5) {
            push @threads, threads->create( sub {
                my $ctxt = shift;
                my $wsock = $ctxt->socket(ZMQ_REP);

                $wsock->connect( "inproc://workers" );

                my $loop = 1;
                while ($loop) {
                    my $message = $wsock->recv;
                    if ($message->data eq 'END') {
                        $loop = 0;
                    } else {
                        $wsock->send( "World " . threads->tid() );
                    }
                }
            }, $ctxt );
        }

        ZeroMQ::device(ZMQ_QUEUE, $clients, $workers);
        $_->join for @threads;
        ok(1);
    }
);

done_testing;