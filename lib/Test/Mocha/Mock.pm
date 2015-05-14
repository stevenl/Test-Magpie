package Test::Mocha::Mock;
# ABSTRACT: Mock objects

use strict;
use warnings;

use Carp 1.22 'croak';
use Test::Mocha::MethodCall;
use Test::Mocha::MethodStub;
use Test::Mocha::Types qw( Matcher Slurpy );
use Test::Mocha::Util
  qw( check_slurpy_arg extract_method_name find_caller find_stub );
use Try::Tiny;
use Types::Standard qw( ArrayRef HashRef Str );
use UNIVERSAL::ref;

our $AUTOLOAD;

my $CaptureMode    = 0;
my $NumMethodCalls = 0;
my $LastMethodCall;

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

    if ($CaptureMode) {
        $NumMethodCalls++;
        $LastMethodCall = $method_call;
        return;
    }

    # record the method call to allow for verification
    push @{ $self->__calls }, $method_call;

    # find a stub to return a response
    if ( my $stub = find_stub( $self, $method_call ) ) {
        return $stub->execute_next_response( $self, @args );
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
    $CaptureMode    = 1;
    $NumMethodCalls = 0;
    $LastMethodCall = undef;

    try {
        # coderef should include a method call on mock
        # which should be executed by AUTOLOAD
        $coderef->();
    }
    catch {
        $CaptureMode = 0;
        ## no critic (RequireCarping,RequireExtendedFormatting)
        # die() instead of croak() since $_ already includes the caller
        die $_
          if ( m{^No arguments allowed after a slurpy type constraint}sm
            || m{^Slurpy argument must be a type of ArrayRef or HashRef}sm );
        ## use critic
    };
    $CaptureMode = 0;

    croak 'Coderef must have a method invoked on a mock object'
      if $NumMethodCalls == 0;
    croak 'Coderef must not have multiple methods invoked on a mock object'
      if $NumMethodCalls > 1;

    return $LastMethodCall;
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
