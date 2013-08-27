package Test::Mocha::Mock;
# ABSTRACT: Mock objects

use strict;
use warnings;

use Carp qw( croak );
use Test::Mocha::MethodCall;
use Test::Mocha::Types qw( Matcher );
use Test::Mocha::Util qw( extract_method_name get_attribute_value
                          has_caller_package );
use Types::Standard qw( Str );
use UNIVERSAL::ref;

our $AUTOLOAD;

# Attributes:
#
# class
# The name of the class that the object is pretending to be blessed into.

# calls
# An array reference containing a record of all methods called on this mock
# to be used for verification.

# stubs
# Contains all of the methods stubbed for this mock. It maps the method name
# to an array of stubs. Stubs are matched against invocation arguments to
# determine which stub to dispatch to.

sub new {
    # uncoverable pod
    my ($class, %args) = @_;
    ### assert: !defined $args{class} || Str->check( $args{class} )

    my $self = \%args;
    $self->{class} = __PACKAGE__ unless defined $self->{class};
    $self->{calls} = [];
    $self->{stubs} = {};

    return bless $self, $class;
}

sub AUTOLOAD {
    my $self = shift;
    my $method_name = extract_method_name($AUTOLOAD);

    my @invalid_args = grep { Matcher->check($_) } @_;
    croak 'Mock methods may not be called with '
        . 'type constraint arguments: ' . join(', ', @invalid_args)
        unless @invalid_args == 0;

    # record the method call for verification
    my $method_call = Test::Mocha::MethodCall->new(
        name => $method_name,
        args => [@_],
    );

    my $calls = get_attribute_value($self, 'calls');
    my $stubs = get_attribute_value($self, 'stubs');

    push @$calls, $method_call;

    # find a stub to return a response
    if (defined $stubs->{$method_name}) {
        foreach my $stub ( @{$stubs->{$method_name}} ) {
            return $stub->execute
                if $stub->satisfied_by($method_call);
        }
    }
    return;
}

# isa()
# Always returns true. It allows the mock object to C<isa()> any class that
# is required.

sub isa {
    # uncoverable pod
    my ($self, $package) = @_;
    return if (
        $package eq 'Type::Tiny'                  ||
        $package eq 'Moose::Meta::TypeConstraint' ||
        has_caller_package('UNIVERSAL::ref')
    );
    return 1;
}

# does()
# Always returns true. It allows the mock object to C<does()> any role that
# is required.

sub does {
    # uncoverable pod
    return 1;
}

# ref()
# Returns the name of the class that this object is pretending to be.
# C<ref()> can be called either as a method or as a function.

sub ref {
    # uncoverable pod
    return $_[0]->{class};
}

# can()
# Always returns a reference to the C<AUTOLOAD()> method. It allows the mock
# object to C<can()> do any method that is required.

sub can {
    # uncoverable pod
    my ($self, $method_name) = @_;
    return sub {
        $AUTOLOAD = $method_name;
        goto &AUTOLOAD;
    };
}

1;
