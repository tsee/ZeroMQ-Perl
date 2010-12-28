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
use Test::Exception;
use ZeroMQ qw/:all/;

{
    my $cxt = ZeroMQ::Context->new(1);
    isa_ok($cxt, 'ZeroMQ::Context');

    my $main_socket = $cxt->socket(ZMQ_UPSTREAM);
    isa_ok($main_socket, "ZeroMQ::Socket");
    $main_socket->close;
    my $t = threads->new(sub {
        note "created thread " . threads->tid;
        my $sock = $cxt->socket( ZMQ_UPSTREAM );
        ok $sock, "created server socket";
        lives_ok {
            $sock->bind("inproc://myPrivateSocket");
        } "bound server socket";
    
        my $client = $cxt->socket(ZMQ_DOWNSTREAM); # sender
        ok $client, "created client socket";
        lives_ok {
            $client->connect("inproc://myPrivateSocket");
        } "connected client socket";

        $client->send( "Wee Woo" );
        my $data = $sock->recv();
        my $ok = is $data->data, "Wee Woo", "got same message";
        return $ok;
    });

    note "Now waiting for thread to join";
    my $ok = $t->join();

    note "Thread joined";
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
};

done_testing;

