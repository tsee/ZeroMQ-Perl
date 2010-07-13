package ZeroMQ;
use 5.008;
use strict;
use warnings;
use Carp 'croak';

our $VERSION = '0.01';
our @ISA = qw(Exporter);

# TODO: keep in sync with docs below and Build.PL
our %EXPORT_TAGS = ( 'all' => [
# socket types
  qw(
    ZMQ_REQ ZMQ_REP

    ZMQ_PUB ZMQ_SUB

    ZMQ_DOWNSTREAM ZMQ_UPSTREAM

    ZMQ_PAIR
  ),
# socket recv flags
  qw(
      ZMQ_NOBLOCK
  ),
# get/setsockopt options
  qw(
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
  ),
] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

require XSLoader;
XSLoader::load('ZeroMQ', $VERSION);
require Exporter;

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;

    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&ZeroMQ::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) {
	if ($error =~  /is not a valid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	} else {
	    croak $error;
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#	if ($] >= 5.00561) {
#	    *$AUTOLOAD = sub () { $val };
#	}
#	else {
	    *$AUTOLOAD = sub { $val };
#	}
    }
    goto &$AUTOLOAD;
}



1;
__END__

=head1 NAME

ZeroMQ - A ZeroMQ2 wrapper for Perl

=head1 SYNOPSIS

  use ZeroMQ qw/:all/;
  
  my $cxt = ZeroMQ::Context->new;
  my $sock = ZeroMQ::Socket->new($cxt, ZMQ_REP);
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
