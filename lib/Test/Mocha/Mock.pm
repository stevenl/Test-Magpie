package Test::Mocha::Mock;
# ABSTRACT: Mock objects

use strict;
use warnings;

use Carp 1.22 'croak';
use Test::Mocha::MethodCall;
use Test::Mocha::MethodStub;
use Test::Mocha::Types qw( Matcher Slurpy );
use Test::Mocha::Util
  qw( check_slurpy_args extract_method_name find_caller find_stub );
use Types::Standard qw( ArrayRef HashRef Str );
use UNIVERSAL::ref;

our $AUTOLOAD;
our $num_method_calls = 0;
our $last_method_call;
our $last_response;

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

    my %args = (
        mocked_class => $mocked_class,
        calls        => [],            # ArrayRef[ MethodCall ]
        stubs        => {              # $method_name => ArrayRef[ MethodStub ]
            map { $_ => [ $DEFAULT_STUBS{$_} ] }
              keys %DEFAULT_STUBS
        },
    );
    return bless \%args, $class;
}

sub __calls {
    my ($self) = @_;
    return $self->{calls};
}

sub __mocked_class {
    my ($self) = @_;
    return $self->{mocked_class};
}

sub __stubs {
    my ($self) = @_;
    return $self->{stubs};
}

sub AUTOLOAD {
    my ( $self, @args ) = @_;
    check_slurpy_args(@args);

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

    undef $last_method_call;
    undef $last_response;

    $num_method_calls++;

    # record the method call for verification
    $last_method_call = Test::Mocha::MethodCall->new(
        invocant => $self,
        name     => $method_name,
        args     => \@args,
        caller   => [find_caller],
    );
    push @{ $self->__calls }, $last_method_call;

    # find a stub to return a response
    my $stub = find_stub( $self, $last_method_call );
    if ( defined $stub ) {
        # save reference to stub response so it can be restored
        my $responses = $stub->__responses;
        $last_response = $responses->[0] if @{$responses} > 1;

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
