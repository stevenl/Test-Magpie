package Test::Mocha::SpyBase;
# ABSTRACT: Abstract base class for Spy and Mock

use strict;
use warnings;

use Carp 1.22 'croak';
use Types::Standard qw( ArrayRef HashRef );

# class attributes
our $CaptureMode = 0;
my $NumMethodCalls = 0;
my $LastMethodCall;

## no critic (NamingConventions::Capitalization)
sub CaptureMode {
    my ( $class, $value ) = @_;
    return $CaptureMode;
}

sub NumMethodCalls {
    my ( $class, $value ) = @_;

    if ( defined $value ) {
        $NumMethodCalls = $value;
    }
    return $NumMethodCalls;
}

sub LastMethodCall {
    my ( $class, $value ) = @_;

    if ( defined $value ) {
        $LastMethodCall = $value;
    }
    return $LastMethodCall;
}
## use critic

sub __new {
    # uncoverable pod
    my %args = (
        calls => [],  # ArrayRef[ MethodCall ]
        stubs => {},  # $method_name => ArrayRef[ MethodStub ]
    );
    return \%args;
}

sub __calls {
    my ($self) = @_;
    return $self->{calls};
}

sub __stubs {
    my ($self) = @_;
    return $self->{stubs};
}

sub __find_stub {
    # """
    # Returns the first stub that satisfies the given method call.
    # Returns undef if no stub is found.
    # """
    # uncoverable pod
    my ( $self, $method_call ) = @_;
    my $stubs = $self->__stubs;

    return if !defined $stubs->{ $method_call->name };

    foreach my $stub ( @{ $stubs->{ $method_call->name } } ) {
        return $stub if $stub->__satisfied_by($method_call);
    }
    return;
}

sub __capture_method_call {
    # """
    # Get the last method called on a mock object,
    # removes it from the invocation history,
    # and restores the last method stub response.
    # """
    # uncoverable pod
    my ( $class, $coderef ) = @_;

    ### assert: !$CaptureMode
    $NumMethodCalls = 0;
    $LastMethodCall = undef;
    {
        # Execute the coderef. This should in turn include a method call on
        # mock, which should be handled by its AUTOLOAD method.
        local $CaptureMode = 1;
        $coderef->();
    }

    croak 'Coderef must have a method invoked on a mock object'
      if $NumMethodCalls == 0;
    croak 'Coderef must not have multiple methods invoked on a mock object'
      if $NumMethodCalls > 1;

    return $LastMethodCall;
}

1;
