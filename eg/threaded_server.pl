#!/usr/bin/env perl
use strict;
use threads;
use ZeroMQ::Constants qw(ZMQ_XREQ ZMQ_XREP ZMQ_REQ ZMQ_REP ZMQ_QUEUE);
use ZeroMQ::Raw;

my $ctxt = zmq_init();
my $clients = zmq_socket($ctxt, ZMQ_XREP);
my $workers = zmq_socket($ctxt, ZMQ_XREQ);

my ($host, $port);

if (@ARGV >= 2) {
    ($host, $port) = @ARGV;
} elsif (@ARGV) {
    if ($ARGV[0] =~ /^([\w\.]+):(\d+)$/) {
        ($host, $port) = ($1, $2);
    } else {
        $host = $ARGV[0];
    }
}
$host ||= '127.0.0.1';
$port ||= 5566;

print "Connecting to server...\n";

zmq_bind( $clients, "tcp://$host:$port" );
zmq_bind( $workers, "inproc://workers" );

for (1..5) {
    threads->create( sub {
        my $ctxt = shift;
        my $wsock = zmq_socket($ctxt, ZMQ_REP);

        zmq_connect( $wsock, "inproc://workers" );

        while (1) {
            my $message = zmq_recv( $wsock );
            print zmq_msg_data($message), "\n";
            sleep 1; # Do some dummy "work"

            zmq_send( $wsock, "World" );
        }
    }, $ctxt );
}

ZeroMQ::Raw::zmq_device(ZMQ_QUEUE, $clients, $workers);
