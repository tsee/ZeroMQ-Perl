use strict;
use Test::More;

use_ok "ZeroMQ";

{
    my $version = ZeroMQ::version();
    ok $version;
    like $version, qr/^\d+\.\d+\.\d+$/, "dotted version string";

    my ($major, $minor, $patch) = ZeroMQ::version();

    is join('.', $major, $minor, $patch), $version, "list and scalar context";
}

done_testing;