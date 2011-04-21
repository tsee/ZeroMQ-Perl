# This test file is used in xt/rt64944.t, but is also in t/
# because it checks (1) failure cases in ZMQ_RCVMORE, and
# (2) shows how non-blocking recv() should be handled

use strict;
use Test::More;
use Test::Requires qw( Test::TCP );

BEGIN {
    use_ok "ZeroMQ";
    use_ok "ZeroMQ::Raw";
    use_ok "ZeroMQ::Constants", ":all";
}

subtest 'blocking recv' => sub {
    test_tcp(
        client => sub {
            my $port = shift;
            my $ctxt = ZeroMQ::Context->new();
            my $sock = $ctxt->socket(ZMQ_SUB);
    
            $sock->connect("tcp://127.0.0.1:$port" );
            $sock->setsockopt(ZMQ_SUBSCRIBE, '');
    
            for(1..10) {
                my $msg = $sock->recv();
                is $msg->data(), $_;
            }
        },
        server => sub {
            my $port = shift;
            my $ctxt = ZeroMQ::Context->new();
            my $sock = $ctxt->socket(ZMQ_PUB);
    
            $sock->bind("tcp://127.0.0.1:$port");
            sleep 2;
            for (1..10) {
                $sock->send($_);
            }
            sleep 2;
        }
    );
};
    
subtest 'non-blocking recv (fail)' => sub {
    test_tcp(
        client => sub {
            my $port = shift;
            my $ctxt = ZeroMQ::Context->new();
            my $sock = $ctxt->socket(ZMQ_SUB);
    
            $sock->connect("tcp://127.0.0.1:$port" );
            $sock->setsockopt(ZMQ_SUBSCRIBE, '');
    
            for(1..10) {
                my $msg = $sock->recv(ZMQ_RCVMORE); # most of this call should really fail
            }
            ok(1); # dummy - this is just here to find leakage
        },
        server => sub {
            my $port = shift;
            my $ctxt = ZeroMQ::Context->new();
            my $sock = $ctxt->socket(ZMQ_PUB);
    
            $sock->bind("tcp://127.0.0.1:$port");
            sleep 2;
            for (1..10) {
                $sock->send($_);
            }
            sleep 2;
        }
    );
};

# Code excericising zmq_poll to do non-blocking recv()
subtest 'non-blocking recv (success)' => sub {
    test_tcp(
        client => sub {
            my $port = shift;
            my $ctxt = zmq_init();
            my $sock = zmq_socket( $ctxt, ZMQ_SUB);
    
            zmq_connect( $sock, "tcp://127.0.0.1:$port" );
            zmq_setsockopt( $sock, ZMQ_SUBSCRIBE, '');
            my $timeout = time() + 30;
            my $recvd = 0;
            while ( $timeout > time() && $recvd < 10 ) {
                zmq_poll( [ {
                    socket => $sock,
                    events => ZMQ_POLLIN,
                    callback => sub {
                        while (my $msg = zmq_recv( $sock, ZMQ_RCVMORE)) {
                            is ( zmq_msg_data( $msg ), $recvd + 1 );
                            $recvd++;
                        }
                    }
                } ], 1000000 ); # timeout in microseconds, so this is 1 sec
            }
            is $recvd, 10, "got all messages";
        },
        server => sub {
            my $port = shift;
            my $ctxt = ZeroMQ::Context->new();
            my $sock = $ctxt->socket(ZMQ_PUB);
    
            $sock->bind("tcp://127.0.0.1:$port");
            sleep 2;
            for (1..10) {
                $sock->send($_);
            }
            sleep 2;
        }
    );
};
    
# Code excercising AnyEvent + ZMQ_FD to do non-blocking recv
if ($^O ne 'MSWin32' && eval { require AnyEvent } && ! $@) {
    AnyEvent->import; # want AE namespace
    subtest 'non-blocking recv with AnyEvent (success)' => sub {
        test_tcp(
            client => sub {
                my $port = shift;
                my $ctxt = zmq_init();
                my $sock = zmq_socket( $ctxt, ZMQ_SUB);
        
                zmq_connect( $sock, "tcp://127.0.0.1:$port" );
                zmq_setsockopt( $sock, ZMQ_SUBSCRIBE, '');
                my $timeout = time() + 30;
                my $recvd = 0;
                my $cv = AE::cv();
                my $t;
                my $fh = zmq_getsockopt( $sock, ZMQ_FD );
                my $w; $w = AE::io( $fh, 0, sub {
                    while (my $msg = zmq_recv( $sock, ZMQ_RCVMORE)) {
                        is ( zmq_msg_data( $msg ), $recvd + 1 );
                        $recvd++;
                        if ( $recvd >= 10 ) {
                            undef $t;
                            undef $w;
                            $cv->send;
                        }
                    }
                } );
                $t = AE::timer( 30, 1, sub {
                    undef $t;
                    undef $w;
                    $cv->send;
                } );
                $cv->recv;
                is $recvd, 10, "got all messages";
            },
            server => sub {
                my $port = shift;
                my $ctxt = ZeroMQ::Context->new();
                my $sock = $ctxt->socket(ZMQ_PUB);
        
                $sock->bind("tcp://127.0.0.1:$port");
                sleep 2;
                for (1..10) {
                    $sock->send($_);
                }
                sleep 10;
            }
        );
    };
}
    
done_testing;
