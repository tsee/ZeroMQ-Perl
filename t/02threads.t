BEGIN {
     require Config;
     if (!$Config::Config{useithreads}) {
        print "1..0 # Skip: no ithreads\n";
        exit 0;
     }
}

use strict;
use warnings;
use threads;
use File::Spec;


use Test::More tests => 5;
use ZeroMQ qw/:all/;

pass();

{
  my $cxt = ZeroMQ::Context->new(1);
  isa_ok($cxt, 'ZeroMQ::Context');

  my $socket = ZeroMQ::Socket->new($cxt, ZMQ_UPSTREAM);
  my $t = threads->new(sub {
    return 1 if ref($socket) eq 'SCALAR' and not defined $$socket;
    return 1 if ref($cxt) eq 'SCALAR' and not defined $$cxt;
    return 0;
  });
  pass();
  my $ok = $t->join();
  ok($ok, "socket and context not defined in subthread");
}
pass();

