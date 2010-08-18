#!/usr/bin/env perl
use strict;
use threads;
use ZeroMQ qw(ZMQ_XREQ ZMQ_XREP ZMQ_REQ ZMQ_REP ZMQ_QUEUE);

my $ctxt = ZeroMQ::Context->new();
my $clients = $ctxt->socket(ZMQ_XREP);
my $workers = $ctxt->socket(ZMQ_XREQ);

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

$clients->bind( "tcp://$host:$port" );
$workers->bind( "inproc://workers" );

for (1..5) {
    threads->create( sub {
        my $ctxt = shift;
        my $wsock = $ctxt->socket(ZMQ_REP);

        $wsock->connect( "inproc://workers" );

        while (1) {
            my $message = $wsock->recv;
            print $message->data, "\n";
            sleep 1; # Do some dummy "work"

            $wsock->send( "World" );
        }
    }, $ctxt );
}

ZeroMQ::device(ZMQ_QUEUE, $clients, $workers);
