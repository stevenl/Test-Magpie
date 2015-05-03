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
