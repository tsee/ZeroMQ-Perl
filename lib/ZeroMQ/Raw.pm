package ZeroMQ::Raw;
use strict;
use XSLoader;

BEGIN {
    our @ISA = qw(Exporter);
    # XXX it's a hassle, but keep it in sync with ZeroMQ.pm
    # by loading this here, we can make ZeroMQ::Raw independent
    # of ZeroMQ while keeping the dist name as ZeroMQ
    XSLoader::load('ZeroMQ', '0.02_04');
}

our @EXPORT = qw(
    zmq_init
    zmq_term

    zmq_msg_close
    zmq_msg_data
    zmq_msg_init
    zmq_msg_init_data
    zmq_msg_init_size
    zmq_msg_size
    zmq_msg_copy
    zmq_msg_move

    zmq_bind
    zmq_close
    zmq_connect
    zmq_getsockopt
    zmq_recv
    zmq_send
    zmq_setsockopt
    zmq_socket
);

1;

__END__

=head1 NAME

ZeroMQ::Raw - Low-level API for ZeroMQ

=head1 FUNCTIONS

=head2 zmq_init

=head2 zmq_term

=head2 zmq_msg_close

=head2 zmq_msg_data

=head2 zmq_msg_init

=head2 zmq_msg_init_data

=head2 zmq_msg_init_size

=head2 zmq_msg_size

=head2 zmq_bind

=head2 zmq_close

=head2 zmq_connect

=head2 zmq_getsockopt

=head2 zmq_recv

=head2 zmq_send

=head2 zmq_setsockopt

=head2 zmq_socket

=cut
