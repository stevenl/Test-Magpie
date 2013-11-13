package Test::Mocha::Util;
# ABSTRACT: Internal utility functions

use strict;
use warnings;

# smartmatch dependencies
use 5.010001;
use experimental qw( smartmatch );

use Carp         qw( confess croak );
use Exporter     qw( import );
use Scalar::Util qw( blessed looks_like_number refaddr );
use Test::Builder;
use Try::Tiny;

our @EXPORT_OK = qw(
    extract_method_name
    find_caller
    find_stub
    getattr
    get_method_call
    has_caller_package
    is_called
    match
);

$Carp::Internal{'Test::Mocha'}++;

my $TB = Test::Builder->new;

sub extract_method_name {
    # """Extracts the method name from its fully qualified name."""
    # uncoverable pod
    my ( $method_name ) = @_;
    $method_name =~ s/.*:://;
    return $method_name;
}

sub find_caller {
    # """Search the call stack to find an external caller"""
    # uncoverable pod
    my ( $package, $file, $line );

    for ( my $i = 1; 1; $i++ ) {
        ( $package, $file, $line ) = caller($i);
        last if $package ne 'UNIVERSAL::ref';
    }
    return ( $file, $line );
}

sub find_stub {
    # uncoverable pod
    my ( $mock, $method_call ) = @_;

    my $stubs = getattr( $mock, 'stubs' );
    return unless defined $stubs->{ $method_call->name };

    foreach my $stub ( @{ $stubs->{ $method_call->name } } ) {
        return $stub if $stub->satisfied_by( $method_call );
    }
    return;
}

sub getattr {
    # """Safely get the attribute value of an object."""
    # uncoverable pod
    my ( $object, $attribute ) = @_;

    # uncoverable branch true
    confess "getattr() must be given an object"
        if not ref $object;
    confess "Attribute '$attribute' does not exist for object '$object'"
        if not exists $object->{$attribute};

    return $object->{$attribute};
}

sub get_method_call {
    # """
    # Get the last method called on a mock object,
    # removes it from the invocation history,
    # and restores the last method stub execution.
    # """
    # uncoverable pod
    my ( $coderef ) = @_;

    try {
        $coderef->();
    }
    catch {
        die $_ if /^(?:
            No\ arguments\ allowed\ after\ a\ slurpy\ type\ constraint
                |
            Slurpy\ argument\ must\ be\ a\ type\ of\ ArrayRef\ or\ HashRef
        )/x;
    };

    croak "Coderef must have a single method invocation on a mock object"
        if $Test::Mocha::Mock::num_method_calls != 1;

    my $method_call = $Test::Mocha::Mock::last_method_call;
    my $mock = $method_call->invocant;

    # restore the last method stub execution
    if ( defined $Test::Mocha::Mocha::last_execution ) {
        my $stub = find_stub( $mock, $method_call );
        unshift @{ $stub->{executions} }, $Test::Mocha::Mocha::last_execution;
    }

    # remove the last method call from the invocation history
    pop @{ getattr( $mock, 'calls' ) };

    return $method_call;
}

sub has_caller_package {
    # """
    # Returns whether the given C<$package> is in the current call stack.
    # """
    # uncoverable pod
    my ( $package ) = @_;

    my $level = 1;
    while ( my ($caller) = caller $level++ ) {
        return 1 if $caller eq $package;
    }
    return;
}

sub is_called {
    # """
    # Tests whether the given method call was invoked the correct number of
    # times. The test is run as a Test::Builder test.
    # """
    # uncoverable pod
    my ( $method_call, %options ) = @_;

    my $mock  = $method_call->invocant;
    my $calls = getattr( $mock, 'calls' );

    my $got = grep { $method_call->satisfied_by($_) } @$calls;
    my $exp;
    my $test_ok;

    # uncoverable branch false count:4
    if ( defined $options{times} ) {
        $exp = $options{times};
        $test_ok = $got == $options{times};
    }
    elsif ( defined $options{at_least} ) {
        $exp = "at least $options{at_least}";
        $test_ok = $got >= $options{at_least};
    }
    elsif ( defined $options{at_most} ) {
        $exp = "at most $options{at_most}";
        $test_ok = $got <= $options{at_most};
    }
    elsif ( defined $options{between} ) {
        my ( $lower, $upper ) = @{ $options{between} };
        $exp = "between $lower and $upper";
        $test_ok = $lower <= $got && $got <= $upper;
    }

    my $test_name = defined $options{ test_name }
        ? $options{ test_name }
        : sprintf( '%s was called %s time(s)', $method_call, $exp );

    # Test failure report should not trace back to Mocha modules
    local $Test::Builder::Level = 2;

    $TB->ok( $test_ok, $test_name );

    # output diagnostics to aid with debugging
    if ( !$test_ok && !$TB->in_todo ) {
        my $diag = <<END;
Error: unexpected number of calls to '$method_call'
         got: $got time(s)
    expected: $exp time(s)
Complete method call history (most recent call last):
END
        if ( @$calls ) {
            $diag .= ('    '  . $_->stringify_long . "\n") foreach @$calls;
        }
        else {
            $diag .= "    (No methods were called)\n";
        }
        $TB->diag($diag);
    }
    return;
}

sub match {
    # """Match 2 values for equality."""
    # uncoverable pod
    my ($x, $y) = @_;

    # This function uses smart matching, but we need to limit the scenarios
    # in which it is used because of its quirks.

    # ref types must match
    return if ref($x) ne ref($y);

    # objects match only if they are the same object
    if (blessed($x) || ref($x) eq 'CODE') {
        return refaddr($x) == refaddr($y);
    }

    # don't smartmatch on arrays because it recurses
    # which leads to the same quirks that we want to avoid
    if (ref($x) eq 'ARRAY') {
        return if $#{$x} != $#{$y};

        # recurse to handle nested structures
        foreach (0 .. $#{$x}) {
            return if !match( $x->[$_], $y->[$_] );
        }
        return 1;
    }

    if (ref($x) eq 'HASH') {
        # smartmatch only matches the hash keys
        return unless $x ~~ $y;

        # ... but we want to match the hash values too
        foreach (keys %$x) {
            return if !match( $x->{$_}, $y->{$_} );
        }
        return 1;
    }

    # avoid smartmatch doing number matches on strings
    # e.g. '5x' ~~ 5 is true
    return if looks_like_number($x) xor looks_like_number($y);

    return $x ~~ $y;
}

1;
