package Test::Mocha::Spy;
# ABSTRACT: Spy objects

use parent 'Test::Mocha::SpyBase';
use strict;
use warnings;

use Carp 1.22 'croak';
use Scalar::Util 'blessed';
use Test::Mocha::MethodCall;
use Test::Mocha::Util qw( check_slurpy_arg extract_method_name find_caller );
use Types::Standard 'Str';
use UNIVERSAL::ref;

our $AUTOLOAD;

# can() should return a reference to C<AUTOLOAD()> for all methods
my %DEFAULT_STUBS = (
    can => Test::Mocha::MethodStub->new(
        name      => 'can',
        args      => [Str],
        responses => [
            sub {
                my ( $self, $method_name ) = @_;
                return if !$self->__object->can($method_name);
                return sub {
                    $AUTOLOAD = $method_name;
                    goto &AUTOLOAD;
                };
            }
        ],
    ),
    ref => Test::Mocha::MethodStub->new(
        name      => 'ref',
        args      => [],
        responses => [
            sub {
                my ($self) = @_;
                return ref( $self->__object );
            }
        ],
    ),
);

sub __new {
    # uncoverable pod
    my ( $class, $object ) = @_;
    croak "Can't spy on an unblessed reference" if !blessed $object;

    my $args = $class->SUPER::__new;

    $args->{object} = $object;
    $args->{stubs}  = {
        map { $_ => [ $DEFAULT_STUBS{$_} ] }
          keys %DEFAULT_STUBS
    };
    return bless $args, $class;
}

sub __object {
    my ($self) = @_;
    return $self->{object};
}

sub AUTOLOAD {
    my ( $self, @args ) = @_;
    check_slurpy_arg(@args);

    my $method_name = extract_method_name($AUTOLOAD);

    # record the method call for verification
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
    # delegate the method call to the real object
    return $self->__object->$method_name(@args);
}

sub isa {
    # uncoverable pod
    my ( $self, $class ) = @_;

    # Handle internal calls from UNIVERSAL::ref::_hook()
    # when ref($spy) is called
    return 1 if $class eq __PACKAGE__;

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
    #return if $method_name eq 'CARP_TRACE';

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
