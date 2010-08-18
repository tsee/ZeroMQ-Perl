#!/usr/bin/env perl
use strict;
use ZeroMQ qw(ZMQ_REP);

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

my $ctxt = ZeroMQ::Context->new();
my $sock = $ctxt->socket(ZMQ_REP);
$sock->bind( "tcp://$host:$port" );

while (1) {
    my $message = $sock->recv();
    print $message->data, "\n";
    $sock->send("world");
}