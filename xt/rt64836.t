use strict;
use Test::More;
use Test::Requires qw( Test::TCP );
use ZeroMQ qw(ZMQ_PUB ZMQ_SUB ZMQ_SNDMORE);
use Time::HiRes qw(usleep);

BEGIN {
    use_ok "ZeroMQ";
    use_ok "ZeroMQ::Constants", ":all";
}


my $port = empty_port();

test_tcp(
    client => sub {
        my $port = shift;
        my $ctxt = ZeroMQ::Context->new();
        my $sock = $ctxt->socket(ZMQ_SUB);

        $sock->connect("tcp://127.0.0.1:$port" );
        $sock->setsockopt(ZMQ_SUBSCRIBE, '');
        my $data = join '.', time(), $$, rand, {};

        my $msg;
        for my $cnt (0..999) {
            $msg = $sock->recv();
            my $data = $msg->data;
            is($data, $cnt, "Expected $cnt, got $data");
        } 
        $msg = $sock->recv();
        is( $msg->data, "end", "Done!" );
        note "Received all messages";
    },
    server => sub {
        my $port = shift;
        my $ctxt = ZeroMQ::Context->new();
        my $sock = $ctxt->socket(ZMQ_PUB);

        note "Server Binding to port $port\n";
        $sock->bind("tcp://127.0.0.1:$port");

        note "Waiting on client to bind...";
        sleep 2;
        note "Server sending ordered data... (numbers 1..1000)";
        for my $c ( 0 .. 999 ) {
            $sock->send($c, ZMQ_SNDMORE);
        }
        $sock->send("end"); # end of data stream...
        note "Sent all messages";
    }
);

done_testing;
