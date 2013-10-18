package Test::Mocha::Mock;
# ABSTRACT: Mock objects

use strict;
use warnings;

use Carp                qw( croak );
use Test::Mocha::MethodCall;
use Test::Mocha::MethodStub;
use Test::Mocha::Types  qw( Matcher );
use Test::Mocha::Util   qw( extract_method_name find_caller
                            getattr has_caller_package );
use Types::Standard     qw( Str );
use UNIVERSAL::ref;

our $AUTOLOAD;

# Classes for which mock isa() should return false
my %Isnota = (
    'Type::Tiny' => undef,
    'Moose::Meta::TypeConstraint' => undef,
);

# Methods for which mock can() should return false
my %Cannot = (
    # Carp 1.32 will call CARP_TRACE on the mock if can() is true
    CARP_TRACE => undef,
);


# can() should always return a reference to the C<AUTOLOAD()> method
my $CAN = Test::Mocha::MethodStub->new(
    name => 'can',
    args => [ Str ],
)->executes(sub {
    my ($self, $method_name) = @_;
    return sub {
        $AUTOLOAD = $method_name;
        goto &AUTOLOAD;
    };
});

# DOES() should always return true
my $DOES_UC = Test::Mocha::MethodStub->new(
    name => 'DOES',
    args => [ Str ],
)->returns(1);

# does() should always return true
my $DOES_LC = Test::Mocha::MethodStub->new(
    name => 'does',
    args => [ Str ],
)->returns(1);

# isa() should always returns true
my $ISA = Test::Mocha::MethodStub->new(
    name => 'isa',
    args => [ Str ] ,
)->returns(1);


sub new {
    # uncoverable pod
    my $class = shift;
    my $self  = bless {@_}, $class;

    # ArrayRef[ MethodCall ]
    $self->{calls} = [];

    # $method_name => ArrayRef[ MethodStub ]
    $self->{stubs} = {
        can  => [ $CAN     ],
        DOES => [ $DOES_UC ],
        does => [ $DOES_LC ],
        isa  => [ $ISA     ],
    };

    return $self;
}

sub AUTOLOAD {
    my ($self, @args) = @_;
    my $method_name = extract_method_name($AUTOLOAD);

    my @invalid_args = grep { Matcher->check($_) } @args;
    croak 'Mock methods may not be called with '
        . 'type constraint arguments: ' . join(', ', @invalid_args)
        unless @invalid_args == 0;

    # record the method call for verification
    my $method_call = Test::Mocha::MethodCall->new(
        name   => $method_name,
        args   => \@args,
        caller => [ find_caller ],
    );

    my $calls = getattr($self, 'calls');
    my $stubs = getattr($self, 'stubs');

    push @$calls, $method_call;

    # find a stub to return a response
    if ( defined $stubs->{$method_name} ) {
        foreach my $stub ( @{$stubs->{$method_name}} ) {
            return $stub->do_next_execution($self, @args)
                if $stub->satisfied_by($method_call);
        }
    }
    return;
}

# Let AUTOLOAD() handle the UNIVERSAL methods

sub isa {
    # uncoverable pod
    my ($self, $class) = @_;

    # Internal calls: Don't let these be recorded by AUTOLOAD()
    return 1 if $class eq __PACKAGE__;
    # Handle being called as a class method by UNIVERSAL::ref
    return if !ref($self)
        || exists $Isnota{ $class }
        || has_caller_package('UNIVERSAL::ref');

    $AUTOLOAD = 'isa';
    goto &AUTOLOAD;
}

sub DOES {
    # uncoverable pod
    my ($self, $role) = @_;

    # Internal calls: Don't let these be recorded by AUTOLOAD()
    return 1 if $role eq __PACKAGE__;

    return if !ref($self);

    $AUTOLOAD = 'DOES';
    goto &AUTOLOAD;
}

sub can {
    # uncoverable pod
    my ($self, $method_name) = @_;

    # Internal calls: Don't let these be recorded by AUTOLOAD()
    return if exists $Cannot{ $method_name };

    $AUTOLOAD = 'can';
    goto &AUTOLOAD;
}

# Don't let AUTOLOAD() handle DESTROY()
sub DESTROY { }

1;
