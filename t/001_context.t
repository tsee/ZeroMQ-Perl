use strict;
use Test::More;
use Test::Exception;

use_ok "ZeroMQ";

lives_ok {
    my $context = ZeroMQ::Context->new()
} "sane allocation / cleanup for context";

# Should probably run this test under valgrind to make sure
# we're not leaking memory

done_testing;