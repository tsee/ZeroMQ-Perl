use strict;
use Test::More;
use Test::Exception;

use_ok "ZeroMQ";

lives_ok {
    my $msg = ZeroMQ::Message->new("hoge");
} "sane allocation / cleanup for message";

# Should probably run this test under valgrind to make sure
# we're not leaking memory

done_testing;