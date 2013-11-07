package Test::Mocha::MethodStub;
# ABSTRACT: Objects to represent stubbed methods with arguments and responses

use strict;
use warnings;

use Carp qw( croak );
use Scalar::Util qw( blessed );
use Test::Mocha::Method;

our @ISA = qw( Test::Mocha::Method );

sub new {
    # uncoverable pod
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->{executions} = []; # ArrayRef[ CodeRef ]

    return $self;
}

sub cast {
    # """Convert the type of the given object to this class"""
    # uncoverable pod
    my ( $class, $obj ) = @_;
    $obj->{executions} = [];
    return bless $obj, $class;
}

sub returns {
    # """Adds a return response to the end of the executions queue."""
    # uncoverable pod
    my ( $self, @return_values ) = @_;

    push @{ $self->{executions} },
        @return_values == 1 ? sub { $return_values[0] } :
        @return_values  > 1 ? sub { @return_values    } :
                              sub { };  # @return_values == 0

    return $self;
}

sub throws {
    # """Adds an exception response to the end of the executions queue."""
    # uncoverable pod
    my ( $self, @exception ) = @_;

    push @{ $self->{executions} },
        # check if first arg is a throwable exception
        blessed($exception[0]) && $exception[0]->can('throw')
          ? sub { $exception[0]->throw }
          : sub { croak @exception     };

    return $self;
}

sub executes {
    # """Adds a callback response to the end of the executions queue."""
    # uncoverable pod
    my ( $self, $callback ) = @_;

    croak 'executes() must be given a coderef'
        unless ref($callback) eq 'CODE';

    push @{ $self->{executions} }, $callback;

    return $self;
}

sub do_next_execution {
    # """Executes the next response."""
    # uncoverable pod
    my ( $self, @args ) = @_;
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
