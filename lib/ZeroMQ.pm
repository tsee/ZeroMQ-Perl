package ZeroMQ;
use 5.008;
use strict;
use warnings;
use Carp 'croak';

our $VERSION = '0.01';
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
  ZMQ_REQ ZMQ_REP

  ZMQ_PUB ZMQ_SUB

  ZMQ_DOWNSTREAM ZMQ_UPSTREAM

  ZMQ_PAIR
) ] );

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

=head1 SEE ALSO

L<ExtUtils::XSpp>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

The ZeroMQ module is

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
