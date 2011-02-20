package ZeroMQ::Poller;
use strict;
use warnings;
use feature qw(:5.10);
use Carp();
use ZeroMQ ();

use ZeroMQ::Raw qw(zmq_poll);
use Scalar::Util qw(blessed);

sub new {
    my ($class, @poll_items) = @_;

    bless {
        _poll_items => [ @poll_items ],
    }, $class;
}

sub poll {
    my ($self, $timeout) = @_;

    $timeout //= -1;
    zmq_poll($self->_raw_poll_items, $timeout);
}

sub _poll_items {
    $_[0]->{_poll_items}
}

sub _raw_poll_items {
    my ($self) = @_;

    unless ($self->{_raw_poll_items}) {
        $self->{_raw_poll_items} = [
            map {
                ( blessed $_ and $_->isa('ZeroMQ::PollItem') ) ? $_->as_hashref : $_
            } @{ $self->_poll_items }
        ];
    }

    return $self->{_raw_poll_items};
}

1;
