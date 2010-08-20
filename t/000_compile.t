use strict;
use Test::More;

use_ok "ZeroMQ";

diag sprintf( 
    "\n   This is ZeroMQ.pm version %s\n   Linked against zeromq2 %s\n",
    $ZeroMQ::VERSION,
    scalar ZeroMQ::version()
);

done_testing;
