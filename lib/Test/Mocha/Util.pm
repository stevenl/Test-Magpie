package Test::Mocha::Util;
# ABSTRACT: Internal utility functions for Test::Mocha

use strict;
use warnings;

# smartmatch dependencies
use 5.010001;
use experimental qw( smartmatch );

use Carp qw( confess );
use Exporter qw( import );
use Scalar::Util qw( blessed looks_like_number refaddr );

our @EXPORT_OK = qw(
    extract_method_name
    get_attribute_value
    has_caller_package
    match
);

# extract_method_name
#
#    $method_name = extract_method_name($full_method_name)
#
# From a fully qualified method name such as Foo::Bar::baz, will return
# just the method name (in this example, baz).

sub extract_method_name {
    # uncoverable pod
    my ($method_name) = @_;
    $method_name =~ s/.*:://;
    return $method_name;
}

# get_attribute_value
#
#    $value = get_attribute_value($object, $attr_name)
#
# Gets value of Moose attributes that have no accessors by accessing the
# underlying meta-object of the class.

sub get_attribute_value {
    # uncoverable pod
    my ($object, $attribute) = @_;

    confess "Attribute '$attribute' does not exist for object '$object'"
        if not defined $object->{$attribute};

    return $object->{$attribute};
}

# has_caller_package
#
#    $bool = has_caller_package($package_name)
#
# Returns whether the given C<$package> is in the current call stack.

sub has_caller_package {
    # uncoverable pod
    my $package = shift;

    my $level = 1;
    while (my ($caller) = caller $level++) {
        return 1 if $caller eq $package;
    }
    return;
}

# match
#
#    $bool = match($x, $y)
#
# Match 2 values for equality.

sub match {
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
