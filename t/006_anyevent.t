use strict;
use Test::More;
use Test::Requires qw( Test::TCP AnyEvent );

BEGIN {
    use_ok "ZeroMQ::Raw";
    use_ok "ZeroMQ::Constants", ":all";
}

test_tcp(
    client => sub {
        my $port = shift;
        my $ctxt = zmq_init(1);
        my $sock = zmq_socket( $ctxt, ZMQ_REQ );

        zmq_connect( $sock, "tcp://127.0.0.1:$port" );
        my $data = join '.', time(), $$, rand, {};
        zmq_send( $sock, $data );
        my $msg = zmq_recv( $sock );
        is $data, zmq_msg_data( $msg ), "Got back same data";
    },
    server => sub {
        my $port = shift;
        my $ctxt = zmq_init(1);
        my $sock = zmq_socket( $ctxt, ZMQ_REP );
        zmq_bind( $sock, "tcp://127.0.0.1:$port" );

        my $fh = zmq_getsockopt( $sock, ZMQ_FD );

        my $cv = AE::cv;
        my $w; $w = AE::io $fh, 0, sub {
            if (my $msg = zmq_recv( $sock, ZMQ_RCVMORE )) {
                undef $w;
                $cv->send( $msg );
            }
        };

        note "Waiting...";
        my $msg = $cv->recv;
        zmq_send( $sock, zmq_msg_data( $msg ) );
        exit 0;
    }
);

done_testing;
