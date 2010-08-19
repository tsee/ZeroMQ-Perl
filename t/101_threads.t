BEGIN {
     require Config;
     if (!$Config::Config{useithreads}) {
        print "1..0 # Skip: no ithreads\n";
        exit 0;
     }
}

use strict;
use warnings;
use threads;
use Test::More;
use ZeroMQ qw/:all/;

{
    my $cxt = ZeroMQ::Context->new(1);
    isa_ok($cxt, 'ZeroMQ::Context');

    my $main_socket = $cxt->socket(ZMQ_UPSTREAM);
    isa_ok($main_socket, "ZeroMQ::Socket");
    my $t = threads->new(sub {
        my $sock = $cxt->socket( ZMQ_UPSTREAM );
        $sock->bind("inproc://myPrivateSocket");
    
        my $client = $cxt->socket(ZMQ_DOWNSTREAM); # sender
        $client->connect("inproc://myPrivateSocket");

        $client->send( "Wee Woo" );
        my $data = $sock->recv();
        my $ok = ($data->data eq "Wee Woo");
        return $ok;
    });
    my $ok = $t->join();
    ok($ok, "socket and context not defined in subthread");
}

{
    my $msg = ZeroMQ::Message->new( "Wee Woo" );
    my $t = threads->new( sub {
        return $msg->data eq "Wee Woo" &&
            $msg->size == 7;
    });

    my $ok = $t->join();
    ok $ok, "message duped correctly";
}

done_testing;

