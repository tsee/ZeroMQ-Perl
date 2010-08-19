package ZeroMQ;
use 5.008;
use strict;

our $VERSION = '0.01';
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
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

require XSLoader;
XSLoader::load('ZeroMQ', $VERSION);

our %SERIALIZERS;
our %DESERIALIZERS;
eval {
    require JSON;
    $SERIALIZERS{json} = \&JSON::encode_json;
    $DESERIALIZERS{json} = \&JSON::decode_json;
};

sub register_read_type { $SERIALIZERS{$_[0]} = $_[1] }
sub register_write_type { $DESERIALIZERS{$_[0]} = $_[1] }

sub ZeroMQ::Context::socket {
    return ZeroMQ::Socket->new(@_); # $_[0] should contain the context
}

1;
__END__

=head1 NAME

ZeroMQ - A ZeroMQ2 wrapper for Perl

=head1 SYNOPSIS

  use ZeroMQ qw/:all/;
  
  my $cxt = ZeroMQ::Context->new;
  my $sock = $cxt->socket(ZMQ_REP);
  $sock->bind($addr);
  
  my $msg;
  foreach (1..$roundtrip_count) {
    $msg = $sock->recv();
    die "Bad size" if $msg->size() != $msg_size;
    $sock->send($msg);
  }

See the F<xt/> directory for full examples.

=head1 DESCRIPTION

The C<ZeroMQ> module is a wrapper of the 0MQ message
passing library for Perl. It's a thin wrapper around the
C++ API.

Loading C<ZeroMQ> will make the L<ZeroMQ::Context>,
L<ZeroMQ::Socket>, and L<ZeroMQ::Message> classes available
as well.

=head2 EXPORTS

You may choose to import one or more (using the C<:all> import tag)
constants into your namespace by supplying arguments to the
C<use ZeroMQ> call as shown in the synopsis above.

The exportable constants are:

=over 2

=item *

Socket types
  
    ZMQ_REQ ZMQ_REP
    ZMQ_PUB ZMQ_SUB
    ZMQ_DOWNSTREAM ZMQ_UPSTREAM
    ZMQ_PAIR

=item *

Socket recv flags

      ZMQ_NOBLOCK

=item *

get/setsockopt options

    ZMQ_RCVMORE
    ZMQ_HWM
    ZMQ_SWAP
    ZMQ_AFFINITY
    ZMQ_IDENTITY
    ZMQ_RATE
    ZMQ_RECOVERY_IVL
    ZMQ_MCAST_LOOP
    ZMQ_SNDBUF
    ZMQ_RCVBUF

    ZMQ_SUBSCRIBE
    ZMQ_UNSUBSCRIBE

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

L<ExtUtils::XSpp>, L<Module::Build::WithXSpp>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

The ZeroMQ module is

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
