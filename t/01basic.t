use strict;
use warnings;
use File::Spec;

use Test::More tests => 2;
use ZeroMQ;

pass();

{
  my $msg = ZeroMQ::Message->new("Hi there");
}
pass();

