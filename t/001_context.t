use strict;
use Test::More;
use Test::Exception;
BEGIN {
    use_ok "ZeroMQ::Raw", qw(
        zmq_init
        zmq_term
    );
}

lives_ok {
    my $context = zmq_init(5);
    isa_ok $context, "ZeroMQ::Raw::Context";
    zmq_term( $context );
} "sane allocation / cleanup for context";

# Should probably run this test under valgrind to make sure
# we're not leaking memory

done_testing;