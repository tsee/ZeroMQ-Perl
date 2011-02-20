package ZeroMQ::PollItem;
use strict;
use warnings;
use feature qw(:5.10);
use Carp();
use ZeroMQ ();

use ZeroMQ::Raw qw(zmq_poll);
use Scalar::Util qw(blessed);

sub new_from_hash {
    my ($class, %args) = @_;

    my ($socket, $fd, $events, $callback) =
        @args{qw(socket fg events callback)};
    die "Need at least one of socket or fd" unless defined $socket or defined $fd;

    bless {
        socket      => $socket,
        fd          => $fd,
        events      => $events,
        callback    => $callback,
    }, $class;
}

sub as_hashref {
    $_[0]->_raw_hashref
}

sub events {
    $_[0]->{events}
}

sub callback {
    $_[0]->{callback}
}

sub socket {
    $_[0]->{socket}
}

sub fd {
    $_[0]->{fd}
}

sub _raw_hashref {
    my ($self) = @_;

    unless ($self->{_raw_hashref}) {
        my $raw_hashref = {
            events      => $self->events,
            callback    => $self->callback,
        };

        if (defined $self->socket) {
            $raw_hashref->{socket} = $self->socket->socket;
        } elsif (defined $self->fd) {
            $raw_hashref->{fd} = $self->fd;
        } else {
            die "Need at least one of socket or fd!";
        }

        $self->{_raw_hashref} = $raw_hashref;
    }

    return $self->{_raw_hashref};
}

1;
