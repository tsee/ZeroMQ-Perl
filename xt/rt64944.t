use strict;
use Test::Valgrind;

do 't/rt64944.t';


__END__
use GTop;
use Test::More;
use Devel::Leak;
use Devel::Peek;
use Scalar::Util qw(weaken);
use Devel::Size;

BEGIN {
   use_ok  'ZeroMQ';
   use_ok  'ZeroMQ::Constants', qw(:all);
}

my $handle;


subtest vanillaperl => sub {
    note "prepare";
    my $ctx = ZeroMQ::Context->new();
    my $start;
    my $end;

    note "socket";
    my $sub = $ctx->socket("ZMQ_SUB");
    $sub->connect("tcp://127.0.0.1:9999");
    $sub->setsockopt(ZMQ_SUBSCRIBE, '');
    sleep 5;
    $start = Devel::Leak::NoteSV($handle);

    my $gtop = GTop->new;
    warn "Calling blcking test";
    my $before = $gtop->mem->total;
    doTest_noblock($sub);
    my $after = $gtop->mem->total;
    warn "Done";

    $end = Devel::Leak::CheckSV($handle);
    warn "gtop: " . ( $after - $before );

#    is($end, $start, "zmq_recv(ZMQ_NOBLOCK) SV Leak Check");
};

sub doTest_block {
    my($sub) = @_;
    for (0..9_999) {
    my $value = $sub->recv();
    undef $value;
    }
};

sub doTest_noblock {
    my($sub) = @_;
    for (0..9_999) {
        my $value=$sub->recv(ZMQ_NOBLOCK);
        warn "got \$! = $!";
    }
};
done_testing;
