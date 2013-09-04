package Test::Mocha::Util;
# ABSTRACT: Internal utility functions

use strict;
use warnings;

# smartmatch dependencies
use 5.010001;
use experimental qw( smartmatch );

use Carp         qw( confess );
use Exporter     qw( import );
use Scalar::Util qw( blessed looks_like_number refaddr );

our @EXPORT_OK = qw(
    extract_method_name
    get_attribute_value
    has_caller_package
    match
);

sub extract_method_name {
    # """Extracts the method name from its fully qualified name."""
    # uncoverable pod
    my ($method_name) = @_;
    $method_name =~ s/.*:://;
    return $method_name;
}

sub get_attribute_value {
    # """Safely get the attribute value of an object."""
    # uncoverable pod
    my ($object, $attribute) = @_;

    # uncoverable branch true
    confess "Attribute '$attribute' does not exist for object '$object'"
        if not defined $object->{$attribute};

    return $object->{$attribute};
}

sub has_caller_package {
    # """
    # Returns whether the given C<$package> is in the current call stack.
    # """
    # uncoverable pod
    my ($package) = @_;

    my $level = 1;
    while (my ($caller) = caller $level++) {
        return 1 if $caller eq $package;
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
