package Test::Mocha::StubbedCall;
# ABSTRACT: Objects to represent stubbed method calls

use strict;
use warnings;

use Carp qw( croak );
use Scalar::Util qw( blessed );

our @ISA = qw( Test::Mocha::MethodCall );

# croak() messages should not trace back to Mocha modules
# to facilitate debugging of user test scripts
our @CARP_NOT = qw( Test::Mocha::Mock );

sub new {
    # uncoverable pod
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->{executions} = []; # ArrayRef[ CodeRef ]

    return $self;
}

sub returns {
    # """Adds a return response to the end of the executions queue."""
    # uncoverable pod
    my ($self, @return_values) = @_;

    push @{ $self->{executions} },
        @return_values == 1
          ? sub { $return_values[0] }
          : sub { @return_values    };

    return $self;
}

sub dies {
    # """Adds a die response to the end of the executions queue."""
    # uncoverable pod
    my ($self, $exception) = @_;

    push @{ $self->{executions} },
        blessed($exception) && $exception->can('throw')
          ? sub { $exception->throw }
          : sub { croak $exception  };

    return $self;
}

sub executes {
    # """Adds a callback response to the end of the executions queue."""
    # uncoverable pod
    my ($self, $callback) = @_;

    croak 'executes() must be given a coderef'
        unless ref($callback) eq 'CODE';

    push @{ $self->{executions} }, $callback;

    return $self;
}

sub do_next_execution {
    # """Executes the next response."""
    # uncoverable pod
    my ($self, @args) = @_;
    my $executions = $self->{executions};

    # return undef by default
    return if @$executions == 0;

    # shift the next execution off the front of the queue
    # ... except for the last one
    my $execution = @$executions > 1
        ? shift(@$executions)
        : $executions->[0];

    return $execution->(@args);
}

1;
