package ZeroMQ::Socket;
use strict;
use Carp();
use ZeroMQ ();

use Scalar::Util qw(blessed);

BEGIN {
    my @map = qw(
        setsockopt
        getsockopt
        bind
        connect
        close
    );
    foreach my $method (@map) {
        my $code = << "EOSUB";
            sub $method {
                my \$self = shift;
                ZeroMQ::Raw::zmq_$method( \$self->socket, \@_ );
            }
EOSUB
        eval $code;
        die if $@;
    }
}

sub new {
    my ($class, $ctxt, @args) = @_;

    if ( eval { $ctxt->isa( 'ZeroMQ::Context' ) } ) {
        $ctxt = $ctxt->ctxt;
    }

    bless {
        _socket => ZeroMQ::Raw::zmq_socket( $ctxt, @args ),
    }, $class;
}

sub socket {
    $_[0]->{_socket};
}

sub recv {
    my ($self, $flags) = @_;

    $flags ||= 0;
    my $rawmsg = ZeroMQ::Raw::zmq_recv( $self->socket, $flags );
    return $rawmsg ?
        ZeroMQ::Message->new_from_message( $rawmsg ) :
        ()
    ;
}

sub send {
    my ($self, $msg, $flags) = @_;

    if (blessed $msg and $msg->isa( 'ZeroMQ::Message' ) ) {
        $msg = $msg->message;
    }

    $flags ||= 0;

    ZeroMQ::Raw::zmq_send( $self->socket, $msg, $flags );
}

sub recv_as {
    my ($self, $type) = @_;

    my $deserializer = ZeroMQ->_get_deserializer( $type );
    if (! $deserializer ) {
        Carp::croak("No deserializer $type found");
    }

    my $msg = $self->recv();
    $deserializer->( $msg->data );
}

sub send_as {
    my ($self, $type, $data) = @_;

    my $serializer = ZeroMQ->_get_serializer( $type );
    if (! $serializer ) {
        Carp::croak("No serializer $type found");
    }

    $self->send( $serializer->( $data ) );
}

1;

__END__

=head1 NAME

ZeroMQ::Socket - A 0MQ Socket object

=head1 SYNOPSIS

  use ZeroMQ qw/:all/;
  
  my $cxt = ZeroMQ::Context->new;
  my $sock = ZeroMQ::Socket->new($cxt, ZMQ_REP);

=head1 DESCRIPTION

0MQ sockets present an abstraction of a asynchronous message queue,
with the exact queueing semantics depending on the socket type in use.

=head2 Key differences to conventional sockets

Quoting the 0MQ manual:

Generally speaking, conventional sockets present a synchronous interface
to either connection-oriented reliable byte streams (C<SOCK_STREAM>),
or connection-less unreliable datagrams (C<SOCK_DGRAM>). In comparison,
0MQ sockets present an abstraction of an asynchronous message queue,
with the exact queueing semantics depending on the socket type in use.
Where conventional sockets transfer streams of bytes or discrete
datagrams, 0MQ sockets transfer discrete messages.

0MQ sockets being asynchronous means that the timings of the physical
connection setup and teardown, reconnect and effective delivery are
transparent to the user and organized by 0MQ itself. Further, messages
may be queued in the event that a peer is unavailable to receive them.

Conventional sockets allow only strict one-to-one (two peers), many-to-one
(many clients, one server), or in some cases one-to-many (multicast)
relationships. With the exception of C<ZMQ_PAIR>, 0MQ sockets may be
connected to multiple endpoints using c<connect()>, while simultaneously
accepting incoming connections from multiple endpoints bound to the socket
using c<bind()>, thus allowing many-to-many relationships.

=head2 Socket types

For detailed explanations of the socket types, check the official
0MQ documentation. This is just a short list of types:

=over 2

=item Request-reply pattern

The C<ZMQ_REQ> type is for the client that sends, then receives.
The C<ZMQ_REP> type is for the server that receives a message, then answers.

=item Publish-subscribe pattern

The C<ZMQ_PUB> type is for publishing messages to an arbitrary number of
subscribers only. The C<ZMQ_SUB> type is for subscribers that receive messages.

=item Pipeline pattern

The C<ZMQ_UPSTREAM> socket type sends messages in a pipeline pattern.
C<ZMQ_DOWNSTREAM> receives them.

=item Exclusive pair pattern

The C<ZMQ_PAIR> type allows bidirectional message passing between two
participants.

=back

=head1 METHODS

=head2 new

Creates a new C<ZeroMQ::Socket>.

First argument must be the L<ZeroMQ::Context> in which the socket
is to live. Second argument is the socket type.

The newly created socket is initially unbound, and not associated
with any endpoints. In order to establish a message flow a socket
must first be connected to at least one endpoint with the C<connect>
method or at least one endpoint must be created for accepting
incoming connections with the C<bind> method.

=head2 bind

The C<bind($endpoint)> method function creates an endpoint for accepting
connections and binds it to the socket.

Quoting the 0MQ manual:
The endpoint argument is a string consisting of two parts as
follows: C<transport://address>. The transport part specifies the
underlying transport protocol to use. The meaning of the address part
is specific to the underlying transport protocol selected.

The following transports are defined. Refer to the 0MQ manual for
details.

=over 2

=item inproc

Local in-process (inter-thread) communication transport.

=item ipc

Local inter-process communication transport.

=item tcp

Unicast transport using TCP.

=item pgm, epgm

Reliable multicast transport using PGM.

=back

With the exception of C<ZMQ_PAIR> sockets, a single socket may be connected
to multiple endpoints using C<connect($endpoint)>, while simultaneously
accepting incoming connections from multiple endpoints bound to the socket
using C<bind($endpoint>)>. The exact semantics depend on the socket type.

=head2 connect

Connect to an existing endpoint. Takes an enpoint string as argument,
see the documentation for C<bind($endpoint)> above.

=head2 close

=head2 send

The C<send($msg, $flags)> method queues the given message to be sent to the
socket. The flags argument is a combination of the flags defined below.

=head2 send_as( $type, $message, $flags )

=over 2

=item ZMQ_NOBLOCK

Specifies that the operation should be performed in non-blocking mode.
If the message cannot be queued on the socket, the C<send()> method
fails with errno set to EAGAIN.

=item ZMQ_SNDMORE

Specifies that the message being sent is a multi-part message, and
that further message parts are to follow. Refer to the 0MQ manual
for details regarding multi-part messages.

=back

=head2 recv

The C<my $msg = $sock-E<gt>recv($flags)> method receives a message from
the socket and returns it as a new C<ZeroMQ::Message> object.
If there are no messages available on the specified socket
the C<recv()> method blocks until the request can be satisfied.
The flags argument is a combination of the flags defined below.

=head2 recv_as( $type, $flags )

=over 2

=item ZMQ_NOBLOCK

Specifies that the operation should be performed in non-blocking mode.
If there are no messages available on the specified socket, the
C<$sock-E<gt>recv(ZMQ_NOBLOCK)> method call returns C<undef> and sets C<$ERRNO>
to C<EAGAIN>.

=back

=head2 getsockopt

The C<my $optval = $sock-E<gt>getsockopt(ZMQ_SOME_OPTION)> method call
retrieves the value for the given socket option.

The following options can be retrieved. For a full explanation
of the options, please refer to the 0MQ manual.

=over 2

=item ZMQ_RCVMORE: More message parts to follow

=item ZMQ_HWM: Retrieve high water mark

=item ZMQ_SWAP: Retrieve disk offload size

=item ZMQ_AFFINITY: Retrieve I/O thread affinity

=item ZMQ_IDENTITY: Retrieve socket identity

=item ZMQ_RATE: Retrieve multicast data rate

=item ZMQ_RECOVERY_IVL: Get multicast recovery interval

=item ZMQ_MCAST_LOOP: Control multicast loopback

=item ZMQ_SNDBUF: Retrieve kernel transmit buffer size

=item ZMQ_RCVBUF: Retrieve kernel receive buffer size

=back

=head2 setsockopt

The C<$sock-E<gt>setsockopt(ZMQ_SOME_OPTION, $value)> method call
sets the specified option to the given value.

The following socket options can be set. For details, please
refer to the 0MQ manual:

=over 2

=item ZMQ_HWM: Set high water mark

=item ZMQ_SWAP: Set disk offload size

=item ZMQ_AFFINITY: Set I/O thread affinity

=item ZMQ_IDENTITY: Set socket identity

=item ZMQ_SUBSCRIBE: Establish message filter

=item ZMQ_UNSUBSCRIBE: Remove message filter

=item ZMQ_RATE: Set multicast data rate

=item ZMQ_RECOVERY_IVL: Set multicast recovery interval

=item ZMQ_MCAST_LOOP: Control multicast loopback

=item ZMQ_SNDBUF: Set kernel transmit buffer size

=item ZMQ_RCVBUF: Set kernel receive buffer size

=back

=head1 CAVEATS

C<ZeroMQ::Socket> objects aren't thread safe due to the
underlying library. Therefore, they are currently not cloned when
a new Perl ithread is spawned. The variables in the new thread
that contained the socket in the parent thread will be a
scalar reference to C<undef> in the new thread.
This makes the Perl wrapper thread safe (i.e. no segmentation faults).

=head1 SEE ALSO

L<ZeroMQ>, L<ZeroMQ::Socket>

L<http://zeromq.org>

L<ExtUtils::XSpp>, L<Module::Build::WithXSpp>

=head1 AUTHOR

Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

The ZeroMQ module is

Copyright (C) 2010 by Daisuke Maki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
