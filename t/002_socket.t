use strict;
use Test::More;
use Test::Exception;

use_ok "ZeroMQ";

lives_ok {
    my $context = ZeroMQ::Context->new();
    my $socket  = ZeroMQ::Socket->new( $context, 1 );
} "sane allocation / cleanup for socket";

# Should probably run this test under valgrind to make sure
# we're not leaking memory

done_testing;