package ZeroMQ::Poller;
use strict;
use warnings;

use ZeroMQ::Raw qw(zmq_poll);
use Scalar::Util qw(looks_like_number weaken);

sub new {
    my ($class, @poll_items) = @_;

    bless {
        _poll_items     => \@poll_items,
        _events         => [],
        _named_events   => {},
    }, $class;
}

sub poll {
    my ($self, $timeout) = @_;
    if (! defined $timeout ) {
        $timeout = -1;
    }

    $self->_clear_events();
    zmq_poll($self->_raw_poll_items, $timeout);
}

sub _clear_events {
    my ($self) = @_;

    $self->{_events} = [];
    $self->{_named_events} = {};
}

sub _raw_poll_items {
    my ($self) = @_;

    unless ($self->{_raw_poll_items}) {
        my @raw_poll_items;

        my @poll_items = $self->_poll_items;
        for (my $i = 0; $i < @poll_items; ++$i) {
            push @raw_poll_items,
                $self->_make_raw_poll_item_with_event_callback($poll_items[$i], $i)
            ;
        }

        $self->{_raw_poll_items} = \@raw_poll_items;
    }

    return $self->{_raw_poll_items};
}

sub _make_raw_poll_item_with_event_callback {
    my ($self, $poll_item, $index) = @_;
    my $name = $poll_item->{name};

    my $raw_poll_item = $self->_make_raw_poll_item($poll_item);

    my $callback = $raw_poll_item->{callback};
    weaken $self;
    $raw_poll_item->{callback} = sub {
        $callback->() if $callback;
        $self->_mark_event_received($index, $name);
    };

    return $raw_poll_item;
}

sub _make_raw_poll_item {
    my ($self, $poll_item) = @_;

    my $raw_poll_item = {
        events      => $poll_item->{events},
        callback    => $poll_item->{callback},
    };

    if ( defined $poll_item->{socket} ) {
        $raw_poll_item->{socket} = $poll_item->{socket}->socket;
    } elsif ( defined $poll_item->{fd} ) {
        $raw_poll_item->{fd} = $poll_item->{fd};
    }

    return $raw_poll_item;
}

sub _mark_event_received {
    my ($self, $index, $name) = @_;

    $self->{_events}->[$index] = 1;
    if (defined $name) {
        $self->{_named_events}->{$name} = 1;
    }
}

sub _poll_items {
    @{ $_[0]->{_poll_items} }
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

sub _events {
    $_[0]->{_events}
}

sub _has_event_by_name {
    my ($self, $name) = @_;

    return !!$self->_named_events->{$name};
}

sub _named_events {
    $_[0]->{_named_events}
}

1;

__END__

=head1 NAME

ZeroMQ::Poller - Convenient socket polling object

=head1 SYNOPSIS

  use ZeroMQ qw/:all/;

  my $cxt = ZeroMQ::Context->new()
  my $sock = ZeroMQ::Socket->new($cxt, ZMQ_REP);
  $sock->bind("inproc://amazingsocket");

  my $poller = ZeroMQ::Poller->new(
    {
      name      => 'amazing',
      socket    => $sock,
      events    => ZMQ_POLLIN,
      callback  => sub { do_something_amazing },
    },
  );

  $poller->poll();
  do_another_amazing_thing() if $poller->has_event(0);
  do_a_third_amazing_thing() if $poller->has_event('amazing');

=head1 DESCRIPTION

A C<ZeroMQ::Poller> watches zero or more sockets for events and signals that these have occurred in several ways.  Given a list of sockets and events to watch for, it can directly invoke a callback or simply raise a flag.

=head1 METHODS

=head2 new(@poll_items)

Creates a new C<ZeroMQ::Poller>

The constructor accepts a list of hash references ("poll items"), each of which specifies a socket or file descriptor to watch and what to watch it for.  In addition, each poll item may specify a callback to invoke or a name by which it may be queried.
The accepted keys are:

=over 4

=item socket

Contains the C<ZeroMQ::Socket> item to poll.

=item fd

Contains the file descriptor to poll.  One of C<socket> or C<fd> is required; C<socket> has precedence.

=item events

Some combination of C<ZMQ_POLLIN>, C<ZMQ_POLLOUT>, and C<ZMQ_POLLERR>; the events to trap.

=item callback

A coderef taking no arguments and emitting no return value, invoked when the specified events occur on the socket or file descriptor.  Optional.

=item name

A string, naming the poll item for later use with C<has_event>.

=back

=head2 poll($timeout)

Blocks until there is activity or the given timeout is reached.  If no timeout or a negative timeout is specified, blocks indefinitely.  If a timeout is given, it is interpreted as microseconds.

=head2 has_event($index)

=head2 has_event($name)

Returns true if the poll item at the given index or with the given name reported activity during the last call to C<poll>.

=cut
