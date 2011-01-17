use strict;
use Test::More;
use Test::Requires qw( Test::TCP );
use Data::Dumper;

BEGIN {
    use_ok "ZeroMQ::Raw";
    use_ok "ZeroMQ::Constants", ":all";
}


my $port = empty_port();

test_tcp(
    client => sub {
        my $port = shift;
        my $ctxt = zmq_init();
        my $sock = zmq_socket($ctxt, ZMQ_SUB);
        zmq_connect($sock,"tcp://127.0.0.1:$port" );
        zmq_setsockopt($sock, ZMQ_SUBSCRIBE, '');

        my $cnt = 0;

        while($cnt<1000) {		# expect to receive numbers 1..1000...
            my $rawmsg = undef;
            $rawmsg = zmq_recv($sock);
            my $msg = zmq_msg_data($rawmsg);
            is($msg, $cnt++, "Error -- messages not received in sequence or corrupt");
        } 
        note "OK";
    },
    server => sub {
        my $port = shift;
        my $ctxt = zmq_init();
        my $sock = zmq_socket($ctxt, ZMQ_PUB);

        note "Server Binding to port $port\n";
        zmq_bind($sock, "tcp://127.0.0.1:$port");
        note "Waiting on client to bind...";
        sleep 2;

        note "Server sending ordered data... (numbers 1..1000)";
        for (my $c = 0; $c < 1000; $c++) {
        	my $msg = zmq_msg_init_data($c);
            note zmq_msg_data( $msg );
            zmq_send($sock, $msg);
        	zmq_msg_close($msg);
        }
        note "OK";
    }
);

done_testing;
