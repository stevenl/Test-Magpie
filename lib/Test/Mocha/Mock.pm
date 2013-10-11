package Test::Mocha::Mock;
# ABSTRACT: Mock objects

use strict;
use warnings;

use Carp qw( croak );
use Test::Mocha::MethodCall;
use Test::Mocha::Types  qw( Matcher );
use Test::Mocha::Util   qw( extract_method_name find_caller
                            getattr has_caller_package );
use Types::Standard     qw( Str );
use UNIVERSAL::ref;

our $AUTOLOAD;

sub new {
    # uncoverable pod
    my $class = shift;
    my $self  = {@_};

    $self->{calls} = [];  # ArrayRef[ MethodCall ]
    $self->{stubs} = {};  # $method_name => ArrayRef[ MethodStub ]

    return bless $self, $class;
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
    if (defined $stubs->{$method_name}) {
        foreach my $stub ( @{$stubs->{$method_name}} ) {
            return $stub->do_next_execution($self, @args)
                if $stub->satisfied_by($method_call);
        }
    }
    return;
}

# Don't let AUTOLOAD() handle DESTROY()
sub DESTROY { }

sub isa {
    # """
    # Always returns true. It allows the mock object to C<isa()> any class
    # that is required.
    # """
    # uncoverable pod
    my ($self, $package) = @_;
    return if (
        $package eq 'Type::Tiny'                  ||
        $package eq 'Moose::Meta::TypeConstraint' ||
        has_caller_package('UNIVERSAL::ref')
    );
    return 1;
}

sub does {
    # """
    # Always returns true. It allows the mock object to C<does()> any role
    # that is required.
    # """
    # uncoverable pod
    return 1;
}

sub can {
    # """
    # Always returns a reference to the C<AUTOLOAD()> method. It allows the
    # mock object to C<can()> do any method that is required.
    # """
    # uncoverable pod
    my ($self, $method_name) = @_;
    return sub {
        $AUTOLOAD = $method_name;
        goto &AUTOLOAD;
    };
}

1;
