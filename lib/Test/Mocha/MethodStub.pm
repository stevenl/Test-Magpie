package Test::Mocha::MethodStub;
# ABSTRACT: Objects to represent stubbed methods with arguments and responses

use strict;
use warnings;
use parent 'Test::Mocha::Method';

use Carp 'croak';
use Scalar::Util 'blessed';

sub new {
    # uncoverable pod
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->{executions} ||= [];  # ArrayRef[ CodeRef ]

    return $self;
}

sub __executions {
    my ($self) = @_;
    return $self->{executions};
}

sub cast {
    # """Convert the type of the given object to this class"""
    # uncoverable pod
    my ( $class, $obj ) = @_;
    $obj->{executions} ||= [];
    return bless $obj, $class;
}

sub returns {
    # """Adds a return response to the end of the executions queue."""
    # uncoverable pod
    my ( $self, @return_values ) = @_;

    warnings::warnif( 'deprecated',
        'returns() method is deprecated; use the returns() function instead' );

    push @{ $self->{executions} },
        @return_values == 1 ? sub { $return_values[0] }
      : @return_values > 1  ? sub { @return_values }
      :                       sub { };                  # @return_values == 0

    return $self;
}

sub throws {
    # """Adds an exception response to the end of the executions queue."""
    # uncoverable pod
    my ( $self, @exception ) = @_;

    warnings::warnif( 'deprecated',
        'throws() method is deprecated; use the throws() function instead' );

    push @{ $self->{executions} },
      # check if first arg is a throwable exception
      ( blessed( $exception[0] ) && $exception[0]->can('throw') )
      ? sub { $exception[0]->throw }
      : sub { croak @exception };

    return $self;
}

sub executes {
    # """Adds a callback response to the end of the executions queue."""
    # uncoverable pod
    my ( $self, $callback ) = @_;

    warnings::warnif( 'deprecated',
        'executes() method is deprecated; use the executes() function instead'
    );

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
    return if @{$executions} == 0;

    # shift the next execution off the front of the queue
    # ... except for the last one
    my $execution =
      @{$executions} > 1 ? shift( @{$executions} ) : $executions->[0];

    return $execution->(@args);
}

1;
