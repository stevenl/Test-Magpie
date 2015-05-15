package Test::Mocha::Mock;
# ABSTRACT: Mock objects

use parent 'Test::Mocha::SpyBase';
use strict;
use warnings;

use Test::Mocha::MethodCall;
use Test::Mocha::MethodStub;
use Test::Mocha::Util qw( check_slurpy_arg extract_method_name find_caller );
use Types::Standard 'Str';
use UNIVERSAL::ref;

our $AUTOLOAD;

# Lookup table of classes for which mock isa() should return false
my %NOT_ISA =
  map { $_ => undef } ( 'Type::Tiny', 'Moose::Meta::TypeConstraint', );

# By default, isa(), DOES() and does() should return true for everything, and
# can() should return a reference to C<AUTOLOAD()> for all methods
my %DEFAULT_STUBS = (
    isa => Test::Mocha::MethodStub->new(
        name      => 'isa',
        args      => [Str],
        responses => [ sub { 1 } ],
    ),
    DOES => Test::Mocha::MethodStub->new(
        name      => 'DOES',
        args      => [Str],
        responses => [ sub { 1 } ],
    ),
    does => Test::Mocha::MethodStub->new(
        name      => 'does',
        args      => [Str],
        responses => [ sub { 1 } ],
    ),
    can => Test::Mocha::MethodStub->new(
        name      => 'can',
        args      => [Str],
        responses => [
            sub {
                my ( $self, $method_name ) = @_;
                return sub {
                    $AUTOLOAD = $method_name;
                    goto &AUTOLOAD;
                };
            }
        ],
    ),
);

sub __new {
    # uncoverable pod
    my ( $class, $mocked_class ) = @_;

    my $args = $class->SUPER::__new;

    $args->{mocked_class} = $mocked_class;
    $args->{stubs}        = {
        map { $_ => [ $DEFAULT_STUBS{$_} ] }
          keys %DEFAULT_STUBS
    };
    return bless $args, $class;
}

sub __mocked_class {
    my ($self) = @_;
    return $self->{mocked_class};
}

sub AUTOLOAD {
    my ( $self, @args ) = @_;
    check_slurpy_arg(@args);

    my $method_name = extract_method_name($AUTOLOAD);

    # If a class method or module function, then transform method name
    my $mocked_class = $self->__mocked_class;
    if ($mocked_class) {
        if ( $args[0] eq $mocked_class ) {
            shift @args;
            $method_name = "${mocked_class}->${method_name}";
        }
        else {
            $method_name = "${mocked_class}::${method_name}";
        }
    }

    my $method_call = Test::Mocha::MethodCall->new(
        invocant => $self,
        name     => $method_name,
        args     => \@args,
        caller   => [find_caller],
    );

    if ( $self->CaptureMode ) {
        $self->NumMethodCalls( $self->NumMethodCalls + 1 );
        $self->LastMethodCall($method_call);
        return;
    }

    # record the method call to allow for verification
    push @{ $self->__calls }, $method_call;

    # find a stub to return a response
    if ( my $stub = $self->__find_stub($method_call) ) {
        return $stub->execute_next_response( $self, @args );
    }
    return;
}

# Let AUTOLOAD() handle the UNIVERSAL methods

sub isa {
    # uncoverable pod
    my ( $self, $class ) = @_;

    # Handle internal calls from UNIVERSAL::ref::_hook()
    # when ref($mock) is called
    return 1 if $class eq __PACKAGE__;

    # In order to allow mock methods to be called with other mocks as
    # arguments, mocks cannot have isa() called with type constraints,
    # which are not allowed as arguments.
    return if exists $NOT_ISA{$class};

    $AUTOLOAD = 'isa';
    goto &AUTOLOAD;
}

sub DOES {
    # uncoverable pod
    my ( $self, $role ) = @_;

    # Handle internal calls from UNIVERSAL::ref::_hook()
    # when ref($mock) is called
    return 1 if $role eq __PACKAGE__;

    return if !ref $self;

    $AUTOLOAD = 'DOES';
    goto &AUTOLOAD;
}

sub can {
    # uncoverable pod
    my ( $self, $method_name ) = @_;

    # Handle can('CARP_TRACE') for internal croak()'s (Carp v1.32+)
    return if $method_name eq 'CARP_TRACE';

    $AUTOLOAD = 'can';
    goto &AUTOLOAD;
}

sub ref {  ## no critic (ProhibitBuiltinHomonyms)
           # uncoverable pod
    $AUTOLOAD = 'ref';
    goto &AUTOLOAD;
}

# Don't let AUTOLOAD() handle DESTROY() so that object can be destroyed
sub DESTROY { }

1;
