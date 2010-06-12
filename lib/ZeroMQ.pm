package ZeroMQ;
use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('ZeroMQ', $VERSION);


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
