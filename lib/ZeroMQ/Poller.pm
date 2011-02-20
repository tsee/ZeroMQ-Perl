package ZeroMQ::Poller;
use strict;
use warnings;
use feature qw(:5.10);
use Carp();

use ZeroMQ::Raw qw(zmq_poll);
use Scalar::Util qw(blessed looks_like_number weaken);

use Data::Dumper;

sub new {
    my ($class, @poll_items) = @_;

    bless {
        _poll_items => \@poll_items,
        _events     => [],
    }, $class;
}

sub poll {
    my ($self, $timeout) = @_;
    $timeout //= -1;

    $self->_clear_events();
    #warn Data::Dumper->Dump([$self, $self->_raw_poll_items], [qw(self raw_poll_items)]);
    zmq_poll($self->_raw_poll_items, $timeout);
}

sub _clear_events {
    my ($self) = @_;

    $self->{_events} = [];
}

sub _raw_poll_items {
    my ($self) = @_;

    unless ($self->{_raw_poll_items}) {
        my @raw_poll_items;

        my @poll_items = @{ $self->_poll_items };
        for (my $i = 0; $i < @poll_items; ++$i) {
            push @raw_poll_items,
                $self->_poll_item_to_raw_hashref_with_event_callback($poll_items[$i], $i);
        }

        $self->{_raw_poll_items} = \@raw_poll_items;
    }

    return $self->{_raw_poll_items};
}

sub _poll_item_to_raw_hashref_with_event_callback {
    my ($self, $poll_item, $index, $name) = @_;

    my $hashref = { %{ $self->_poll_item_to_raw_hashref($poll_item) } };

    my $callback = $hashref->{callback};
    weaken $self;
    $hashref->{callback} = sub {
        $callback->() if $callback;
        $self->_mark_event_received($index, $name);
    };

    return $hashref;
}

sub _poll_item_to_raw_hashref {
    my ($self, $poll_item) = @_;

    if ( blessed $poll_item and $poll_item->isa('ZeroMQ::PollItem') ) {
        return $poll_item->as_raw_hashref();
    } else {
        return $poll_item;
    }
}

sub _mark_event_received {
    my ($self, $index, $name) = @_;

    $self->{_events}->[$index] = 1;
}

sub _poll_items {
    $_[0]->{_poll_items}
}

sub has_event {
    my ($self, $which) = @_;

    return ( looks_like_number $which
        ? $self->_has_event_by_index($which) : $self->_has_event_by_name($which)
    );
}

sub _has_event_by_index {
    my ($self, $index) = @_;

    return !!$self->_events->[$index];
}

sub _has_event_by_name {
}

sub _events {
    $_[0]->{_events}
}

1;
