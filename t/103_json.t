use strict;
use Test::More;
use Test::Requires 'JSON';

BEGIN {
    use_ok 'ZeroMQ', qw(ZMQ_PAIR ZMQ_NOBLOCK);
}

{
    my $structure = { foo => "bar" };

    my $cxt = ZeroMQ::Context->new;
    isa_ok($cxt, 'ZeroMQ::Context');
    my $sock = $cxt->socket(ZMQ_PAIR); # Receiver
    isa_ok($sock, 'ZeroMQ::Socket');
  
    $sock->bind("inproc://myPrivateSocket");
  
    my $client = $cxt->socket(ZMQ_PAIR); # sender
    $client->connect("inproc://myPrivateSocket");
  
    ok(!defined($sock->recv(ZMQ_NOBLOCK())));
    ok($client->send_as( json => $structure ) == 0);
    
    my $msg = $sock->recv_as( 'json' );
    ok(defined $msg, "received defined msg");
    is_deeply($msg, $structure, "received correct message");
}

{
    my $cxt = ZeroMQ::Context->new;
    isa_ok($cxt, 'ZeroMQ::Context');
    can_ok($cxt, 'socket');

    my $sock = $cxt->socket(ZMQ_PAIR); # Receiver
    isa_ok($sock, 'ZeroMQ::Socket');
    $sock->bind("inproc://myPrivateSocket");

    my $client = $cxt->socket(ZMQ_PAIR); # sender
    $client->connect("inproc://myPrivateSocket");

    my $structure = {some => 'data', structure => [qw/that is json friendly/]};
    ok($client->send_as( json => $structure ) == 0);

    my $msg = $sock->recv_as('json');
    ok(defined $msg, "received defined msg");

    is_deeply($msg, $structure);
}

  
done_testing;