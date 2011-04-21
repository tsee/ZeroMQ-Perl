package ZeroMQ::Constants;
use strict;
use base qw(Exporter);
use ZeroMQ ();

# TODO: keep in sync with docs below and Makefile.PL

BEGIN {
    my @possibly_nonexistent = qw(
        ZMQ_BACKLOG
        ZMQ_FD
        ZMQ_LINGER
        ZMQ_EVENTS
        ZMQ_RECONNECT_IVL
        ZMQ_SWAP
        ZMQ_TYPE
        ZMQ_VERSION
        ZMQ_VERSION_MAJOR
        ZMQ_VERSION_MINOR
        ZMQ_VERSION_PATCH
    );
    my $version = ZeroMQ::version();
    foreach my $symbol (@possibly_nonexistent) {
        if (! __PACKAGE__->can($symbol) ) {
            no strict 'refs';
            *{$symbol} = sub { Carp::croak("$symbol is not available in zeromq2 $version") };

        };
    }
}

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
        ZMQ_XSUB
        ZMQ_XPUB
        ZMQ_PULL
        ZMQ_PUSH
        ZMQ_UPSTREAM
        ZMQ_DOWNSTREAM
        ZMQ_BACKLOG
        ZMQ_FD
        ZMQ_LINGER
        ZMQ_EVENTS
        ZMQ_RECONNECT_IVL
        ZMQ_TYPE
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
    ),]
);

$EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ];
our @EXPORT_OK = (
    qw(
        ZMQ_RECOVERY_IVL_MSEC
        ZMQ_HAUSNUMERO
        ZMQ_VERSION
        ZMQ_VERSION_MAJOR
        ZMQ_VERSION_MINOR
        ZMQ_VERSION_PATCH
    ),
    @{ $EXPORT_TAGS{'all'} }
);

1;

__END__

=head1 NAME

ZeroMQ::Constants - ZeroMQ Constants

=head1 EXPORTS

You may choose to import one or more (using the C<:all> import tag)
constants into your namespace by supplying arguments to the
C<use ZeroMQ> call as shown in the synopsis above.

The exportable constants are:

=head2 C<:socket> - Socket types and socket options

=over 4

=item ZMQ_PAIR

=item ZMQ_PUB

=item ZMQ_SUB

=item ZMQ_REQ

=item ZMQ_REP

=item ZMQ_XREQ

=item ZMQ_XREP

=item ZMQ_XPUB

=item ZMQ_XSUB

=item ZMQ_PULL

=item ZMQ_PUSH

=item ZMQ_UPSTREAM

=item ZMQ_DOWNSTREAM

=item ZMQ_BACKLOG

=item ZMQ_FD

=item ZMQ_LINGER

=item ZMQ_EVENTS

=item ZMQ_RECONNECT_IVL

=item ZMQ_TYPE

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

=item ZMQ_VERSION

=item ZMQ_VERSION_MAJOR

=item ZMQ_VERSION_MINOR

=item ZMQ_VERSION_PATCH

=item ZMQ_RECOVERY_IVL_MSEC

=back

=head2 uncategorized

=cut

