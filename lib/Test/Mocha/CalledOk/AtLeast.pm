package Test::Mocha::CalledOk::AtLeast;
# ABSTRACT: Concrete subclass of CalledOk for verifying methods called 'atleast' number of times

use strict;
use warnings;
use parent 'Test::Mocha::CalledOk';

sub is {
    # uncoverable pod
    my ( $class, $got, $exp ) = @_;
    return $got >= $exp;
}

sub stringify {
    # uncoverable pod
    my ( $class, $exp ) = @_;
    return "at least $exp time(s)";
}

1;
