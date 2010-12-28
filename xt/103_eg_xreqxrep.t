use strict;
use Test::More;
use Test::TCP;
use Test::Requires 'Parallel::Prefork';
use File::Temp;
BEGIN {
    use_ok "ZeroMQ", qw(ZMQ_REQ ZMQ_REP ZMQ_POLLOUT ZMQ_NOBLOCK);
}

my $parent;
test_tcp(
    server => sub {
        my $port = shift;

        my $ctxt = ZeroMQ::Context->new;
        my $socket = $ctxt->socket(ZMQ_REP);
        $socket->bind( "tcp://127.0.0.1:$port");

        while ( 1 ) {
            my $msg = $socket->recv;
            next unless $msg;
            $socket->send("Thank you " . $msg->data);
        }
    },
    client => sub {
        my $port = shift;

        sleep 2;
        my %children;
        foreach (1..3) {
            my $pid = fork();
            if (! defined $pid) {
                die "Could not fork";
            } elsif ($pid) {
                $parent = $$;
                $children{$pid}++;
            } else {
                my $ctxt = ZeroMQ::Context->new();
                my $client = $ctxt->socket( ZMQ_REQ );
                $client->connect("tcp://127.0.0.1:$port");
                $client->send($$);
                my $msg = $client->recv();
                is $msg->data, "Thank you $$", "child $$ got reply '" . $msg->data . "'";
                exit 0;
            }
        }

        while (%children) {
            if ( my $pid = wait ) {
                delete $children{$pid};
            }
        }
    }
);

done_testing;
