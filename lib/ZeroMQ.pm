package ZeroMQ;
use 5.008;
use strict;

our $VERSION = '0.01_03';
our @ISA = qw(Exporter);

# TODO: keep in sync with docs below and Makefile.PL

our %EXPORT_TAGS = (
# socket types
    socket => [ qw(
        ZMQ_PAIR
        ZMQ_PUB
        ZMQ_SUB
        ZMQ_REQ
        ZMQ_REP
        ZMQ_XREQ
        ZMQ_XREP
        ZMQ_PULL
        ZMQ_PUSH
        ZMQ_UPSTREAM
        ZMQ_DOWNSTREAM
    ),
# socket send/recv flags
    qw(
        ZMQ_NOBLOCK
        ZMQ_SNDMORE
    ),
# get/setsockopt options
    qw(
        ZMQ_HWM
        ZMQ_SWAP
        ZMQ_AFFINITY
        ZMQ_IDENTITY
        ZMQ_SUBSCRIBE
        ZMQ_UNSUBSCRIBE
        ZMQ_RATE
        ZMQ_RECOVERY_IVL
        ZMQ_MCAST_LOOP
        ZMQ_SNDBUF
        ZMQ_RCVBUF
        ZMQ_RCVMORE
    ),
# i/o multiplexing
    qw(
        ZMQ_POLLIN
        ZMQ_POLLOUT
        ZMQ_POLLERR
    ),
    ],
# devices
    device => [ qw(
        ZMQ_QUEUE
        ZMQ_FORWARDER
        ZMQ_STREAMER
    ), ],
# max size of vsm message
    message => [ qw(
        ZMQ_MAX_VSM_SIZE
    ),
# message types
    qw(
        ZMQ_DELIMITER
        ZMQ_VSM
    ),
# message flags
    qw(
        ZMQ_MSG_MORE
        ZMQ_MSG_SHARED
    ), ]
);

$EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ];
our @EXPORT_OK = ( 'ZMQ_HAUSNUMERO', @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

require XSLoader;
XSLoader::load('ZeroMQ', $VERSION);

our %SERIALIZERS;
our %DESERIALIZERS;
sub register_read_type { $DESERIALIZERS{$_[0]} = $_[1] }
sub register_write_type { $SERIALIZERS{$_[0]} = $_[1] }

eval {
    require JSON;
    JSON->import(2.00);
    register_read_type(json => \&JSON::decode_json);
    register_write_type(json => \&JSON::encode_json);
};


sub ZeroMQ::Context::socket {
    return ZeroMQ::Socket->new(@_); # $_[0] should contain the context
}

1;
__END__

=head1 NAME

ZeroMQ - A ZeroMQ2 wrapper for Perl

=head1 SYNOPSIS

    # echo server
    use ZeroMQ qw/:all/;

    my $cxt = ZeroMQ::Context->new;
    my $sock = $cxt->socket(ZMQ_REP);
    $sock->bind($addr);
  
    my $msg;
    foreach (1..$roundtrip_count) {
        $msg = $sock->recv();
        $sock->send($msg);
    }

    # custom serialization
    ZeroMQ::register_read_type(myformat => sub { ... });
    ZeroMQ::register_write_type(myformat => sub { .. });

    $socket->send_as( myformat => $data ); # serialize using above callback
    my $thing = $socket->recv_as( "myformat" );

See the F<eg/> directory for full examples.

=head1 DESCRIPTION

The C<ZeroMQ> module is a wrapper of the 0MQ message passing library for Perl. 
It's a thin wrapper around the C API. Please read L<http://zeromq.org> for
more details on ZeroMQ.

Loading C<ZeroMQ> will make the L<ZeroMQ::Context>, L<ZeroMQ::Socket>, and 
L<ZeroMQ::Message> classes available as well.

=head1 FUNCTIONS

=head2 device($type, $sock1, $sock2)

=head2 register_read_type($name, \&callback)

Register a read callback for a given C<$name>. This is used in C<recv_as()>.
The callback receives the data received from the socket.

=head2 register_write_type($name, \&callback)

Register a write callback for a given C<$name>. This is used in C<send_as()>
The callback receives the Perl structure given to C<send_as()>

=head1 SERIALIZATION

ZeroMQ.pm comes with a simple serialization/deserialization mechanism.

To serialize, use C<register_write_type()> to register a name and an
associated callback to serialize the data. For example, for JSON we do
the following:

    use JSON ();
    ZeroMQ::register_write_type('json' => \&JSON::encode_json);
    ZeroMQ::register_read_type('json' => \&JSON::decode_json);

Then you can use C<send_as()> and C<recv_as()> to specify the serialization type as the
first argument:

    my $ctxt = ZeroMQ::Context->new();
    my $sock = $ctxt->socket( ZMQ_REQ );

    $sock->send_as( json => $complex_perl_data_structure );

The otherside will receive a JSON encoded data. The receivind side
can be written as:

    my $ctxt = ZeroMQ::Context->new();
    my $sock = $ctxt->socket( ZMQ_REP );

    my $complex_perl_data_structure = $sock->recv_as( 'json' );

If you have JSON.pm (must be 2.00 or above), then the JSON serializer / 
deserializer is automatically enabled. If you want to tweak the serializer
option, do something like this:

    my $coder = JSON->new->utf8->pretty; # pretty print
    ZeroMQ::register_write_type( json => sub { $coder->encode($_[0]) } );
    ZeroMQ::register_read_type( json => sub { $coder->decode($_[0]) } );

Note that this will have a GLOBAL effect. If you want to change only
your application, use a name that's different from 'json'.

=head1 EXPORTS

You may choose to import one or more (using the C<:all> import tag)
constants into your namespace by supplying arguments to the
C<use ZeroMQ> call as shown in the synopsis above.

The exportable constants are:

=head1 EXPORTS

=head2 C<:socket> - Socket types and socket options

=over 4

=item ZMQ_PAIR

=item ZMQ_PUB

=item ZMQ_SUB

=item ZMQ_REQ

=item ZMQ_REP

=item ZMQ_XREQ

=item ZMQ_XREP

=item ZMQ_PULL

=item ZMQ_PUSH

=item ZMQ_UPSTREAM

=item ZMQ_DOWNSTREAM

=item ZMQ_NOBLOCK

=item ZMQ_SNDMORE

=item ZMQ_HWM

=item ZMQ_SWAP

=item ZMQ_AFFINITY

=item ZMQ_IDENTITY

=item ZMQ_SUBSCRIBE

=item ZMQ_UNSUBSCRIBE

=item ZMQ_RATE

=item ZMQ_RECOVERY_IVL

=item ZMQ_MCAST_LOOP

=item ZMQ_SNDBUF

=item ZMQ_RCVBUF

=item ZMQ_RCVMORE

=item ZMQ_POLLIN

=item ZMQ_POLLOUT

=item ZMQ_POLLERR

=back

=head2 C<:device> - Device types

=over 4

=item ZMQ_QUEUE

=item ZMQ_FORWARDER

=item ZMQ_STREAMER

=back

=head2 C<:message> - Message Options

=over 4

=item ZMQ_MAX_VSM_SIZE

=item ZMQ_DELIMITER

=item ZMQ_VSM

=item ZMQ_MSG_MORE

=item ZMQ_MSG_SHARED

=back

=head2 miscellaneous

=over 4

=item ZMQ_HAUSNUMERO

=back

=head1 CAVEATS

This is an early release. Proceed with caution, please report
(or better yet: fix) bugs you encounter. Tested againt 0MQ 2.0.7.

Use of the C<inproc://> transport layer doesn't seem to work
between two perl ithreads. This may be due to the fact that right now,
context aren't shared between ithreads and C<inproc> works
only within a single context. Try another transport layer until
contexts can be shared.

=head1 SEE ALSO

L<ZeroMQ::Context>, L<ZeroMQ::Socket>, L<ZeroMQ::Message>

L<http://zeromq.org>

=head1 AUTHOR

Steffen Mueller, C<< <smueller@cpan.org> >>

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 COPYRIGHT AND LICENSE

The ZeroMQ module is

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
