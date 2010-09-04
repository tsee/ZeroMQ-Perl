use strict;
use Test::More;
use Test::SharedFork;
use File::Temp;

BEGIN {
    use_ok "ZeroMQ", qw(ZMQ_REP ZMQ_REQ);
}

my $path = File::Temp->new(UNLINK => 1);
my $pid = fork();
if ($pid == 0) {
    sleep 1; # hmmm, not a good way to do this...
    my $ctxt = ZeroMQ::Context->new();
    my $child = $ctxt->socket( ZMQ_REQ );
    $child->connect( "ipc://$path" );
    $child->send( "Hello from $$" );
    pass "Send successful";
    exit 0;
} elsif ($pid) {
    my $ctxt = ZeroMQ::Context->new();
    my $parent_sock = $ctxt->socket(ZMQ_REP);
    $parent_sock->bind( "ipc://$path" );
    my $msg = $parent_sock->recv;
    is $msg->data, "Hello from $pid", "message is the expected message";
} else {
    die "Could not fork: $!";
}


done_testing;