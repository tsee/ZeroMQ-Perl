package ZeroMQ::PollItem;
use strict;
use warnings;
use feature qw(:5.10);
use Carp();

sub new {
    my ($class, $socket, $fd, $events, $callback) = @_;

    bless {
        _socket     => $socket,
        _fd         => $fd,
        _events     => $events,
        _callback   => $callback,
    }, $class;
}

sub new_from_hash {
    my ($class, %args) = @_;

    my ($socket, $fd, $events, $callback) =
        @args{qw(socket fg events callback)};

    return $class->new($socket, $fd, $events, $callback);
}

sub events {
    $_[0]->{_events}
}

sub callback {
    $_[0]->{_callback}
}

sub socket {
    $_[0]->{_socket}
}

sub fd {
    $_[0]->{_fd}
}

sub as_raw_hashref {
    $_[0]->_raw_hashref
}

sub _raw_hashref {
    my ($self) = @_;

    unless ($self->{_raw_hashref}) {
        my $raw_hashref = {
            events      => $self->events,
            callback    => $self->callback,
        };

        if (defined $self->_raw_socket) {
            $raw_hashref->{socket} = $self->_raw_socket;
        } else {
            $raw_hashref->{fd} = $self->fd;
        }

        $self->{_raw_hashref} = $raw_hashref;
    }

    return $self->{_raw_hashref};
}

sub _raw_socket {
    $_[0]->socket ? $_[0]->socket->socket : undef;
}

1;
