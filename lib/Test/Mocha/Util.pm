package Test::Mocha::Util;
# ABSTRACT: Internal utility functions

use strict;
use warnings;

# smartmatch dependencies
use 5.010001;
use experimental 'smartmatch';

use Carp 'croak';
use Exporter 'import';
use Scalar::Util qw( blessed looks_like_number refaddr );
use Test::Mocha::Types qw( Matcher Slurpy );
use Try::Tiny;
use Types::Standard qw( ArrayRef HashRef );

our @EXPORT_OK = qw(
  check_slurpy_args
  extract_method_name
  find_caller
  find_stub
  get_method_call
  match
);

sub check_slurpy_args {
    # """
    # Checks the arguments list for the presence of a slurpy argument matcher.
    # It will throw an error if it is used incorrectly.
    # Otherwise it will just return silently.
    # """
    # uncoverable pod
    my @args = @_;

    my $i = 0;
    foreach (@args) {
        if ( Slurpy->check($_) ) {
            croak 'No arguments allowed after a slurpy type constraint'
              if $i < $#args;

            my $slurpy = $_->{slurpy};
            croak 'Slurpy argument must be a type of ArrayRef or HashRef'
              unless $slurpy->is_a_type_of(ArrayRef)
              || $slurpy->is_a_type_of(HashRef);
        }
        $i++;
    }
    return;
}

sub extract_method_name {
    # """Extracts the method name from its fully qualified name."""
    # uncoverable pod
    my ($method_name) = @_;
    $method_name =~ s/.*:://sm;
    return $method_name;
}

sub find_caller {
    # """Search the call stack to find an external caller"""
    # uncoverable pod
    my ( $package, $file, $line );

    my $i = 1;
    while () {
        ( $package, $file, $line ) = caller $i++;
        last if $package ne 'UNIVERSAL::ref';
    }
    return ( $file, $line );
}

sub find_stub {
    # uncoverable pod
    my ( $mock, $method_call ) = @_;

    my $stubs = $mock->__stubs;
    return if !defined $stubs->{ $method_call->name };

    foreach my $stub ( @{ $stubs->{ $method_call->name } } ) {
        return $stub if $stub->satisfied_by($method_call);
    }
    return;
}

sub get_method_call {
    # """
    # Get the last method called on a mock object,
    # removes it from the invocation history,
    # and restores the last method stub response.
    # """
    # uncoverable pod
    my ($coderef) = @_;

    try {
        $coderef->();
    }
    catch {
        ## no critic (RequireCarping,RequireExtendedFormatting)
        die $_
          if ( m{^No arguments allowed after a slurpy type constraint}sm
            || m{^Slurpy argument must be a type of ArrayRef or HashRef}sm );
        ## use critic
    };

    croak 'Coderef must have a method invoked on a mock object'
      if $Test::Mocha::Mock::num_method_calls == 0;
    croak 'Coderef must not have multiple methods invoked on a mock object'
      if $Test::Mocha::Mock::num_method_calls > 1;

    my $method_call = $Test::Mocha::Mock::last_method_call;
    my $mock        = $method_call->invocant;

    # restore the last method stub response
    if ( defined $Test::Mocha::Mock::last_response ) {
        my $stub = find_stub( $mock, $method_call );
        unshift @{ $stub->{responses} }, $Test::Mocha::Mock::last_response;
    }

    # remove the last method call from the invocation history
    pop @{ $mock->__calls };

    return $method_call;
}

sub match {
    # """Match 2 values for equality."""
    # uncoverable pod
    my ( $x, $y ) = @_;

    # This function uses smart matching, but we need to limit the scenarios
    # in which it is used because of its quirks.

    # ref types must match
    return if ref $x ne ref $y;

    # objects match only if they are the same object
    if ( blessed($x) || ref($x) eq 'CODE' ) {
        return refaddr($x) == refaddr($y);
    }

    # don't smartmatch on arrays because it recurses
    # which leads to the same quirks that we want to avoid
    if ( ref($x) eq 'ARRAY' ) {
        return if $#{$x} != $#{$y};

        # recurse to handle nested structures
        foreach ( 0 .. $#{$x} ) {
            return if !match( $x->[$_], $y->[$_] );
        }
        return 1;
    }

    if ( ref($x) eq 'HASH' ) {
        # smartmatch only matches the hash keys
        return if not $x ~~ $y;

        # ... but we want to match the hash values too
        foreach ( keys %{$x} ) {
            return if !match( $x->{$_}, $y->{$_} );
        }
        return 1;
    }

    # avoid smartmatch doing number matches on strings
    # e.g. '5x' ~~ 5 is true
    return if looks_like_number($x) xor looks_like_number($y);

    return $x ~~ $y;
}

# sub print_call_stack {
#     # """
#     # Returns whether the given C<$package> is in the current call stack.
#     # """
#     # uncoverable pod
#     my ( $message ) = @_;
#
#     print $message, "\n";
#     my $level = 1;
#     while ( my ( $caller, $file, $line, $sub ) = caller $level++ ) {
#         print "\t[$caller] $sub\n";
#     }
#     return;
# }

1;
