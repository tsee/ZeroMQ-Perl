use strict;
use Test::More;
use Test::TCP;
use ZeroMQ qw(:all);

my $MAX_MESSAGES = 1_000;

my $server = Test::TCP->new(code => sub {
    my $port = shift;
    my $context = ZeroMQ::Context->new();
    my $sender = $context->socket(ZMQ_PUSH);
    $sender->bind("tcp://*:$port");

    # XXX hacky synchronization
    sleep 3;

    # The first message is "0" and signals start of batch
    #$sender->send('0');

    my $ident=0;
    while ($ident < $MAX_MESSAGES) {
        note "sending ".$ident++,"\n";
        $sender->send($ident);
    }

    note "Done sending";
    sleep(1);              # Give 0MQ time to deliver
});

{
    my $context = ZeroMQ::Context->new();

    # Socket to receive messages on
    my $receiver = $context->socket(ZMQ_PULL);
    $receiver->connect("tcp://localhost:" . $server->port);

    for my $expected (1..$MAX_MESSAGES) {
        my $msg = $receiver->recv();
        is $msg->data, $expected;
    }
}

undef $server;

done_testing;

