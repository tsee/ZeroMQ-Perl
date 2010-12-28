package ZeroMQ::Message;
use strict;

sub new {
    my ($class, $data) = @_;
    bless {
        _message => ZeroMQ::Raw::zmq_msg_init_data( $data )
    }, $class;
}

sub new_from_message {
    my ($class, $message) = @_;
    bless {
        _message => $message
    }, $class;
}

sub message {
    $_[0]->{_message};
}

sub data {
    ZeroMQ::Raw::zmq_msg_data( $_[0]->message );
}

sub size {
    ZeroMQ::Raw::zmq_msg_size( $_[0]->message );
}

1;

__END__

=head1 NAME

ZeroMQ::Message - A 0MQ Message object

=head1 SYNOPSIS

  use ZeroMQ qw/:all/;
  
  my $cxt = ZeroMQ::Context->new;
  my $sock = ZeroMQ::Socket->new($cxt, ZMQ_REP);
  my $msg = ZeroMQ::Message->new($text);
  $sock->send($msg);
  my $anothermsg = $sock->recv;

=head1 DESCRIPTION

A C<ZeroMQ::Message> object represents a message
to be passed over a C<ZeroMQ::Socket>.

=head1 METHODS

=head2 new

Creates a new C<ZeroMQ::Message>.

Takes the data to send with the message as argument.

=head2 new_from_message( $rawmsg )

Creates a new C<ZeroMQ::Message>.

Takes a ZeroMQ::Raw::Message object as argument.

=head2 message

Return the underlying ZeroMQ::Raw::Message object.

=head2 size

Returns the length (in bytes) of the contained data.

=head2 data

Returns the data as a (potentially binary) string.

=head1 SEE ALSO

L<ZeroMQ>, L<ZeroMQ::Socket>, L<ZeroMQ::Context>

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
