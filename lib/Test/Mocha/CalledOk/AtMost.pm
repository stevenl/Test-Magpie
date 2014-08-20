package Test::Mocha::CalledOk::AtMost;
# ABSTRACT: Concrete subclass of CalledOk for verifying methods called 'atmost' number of times

use strict;
use warnings;
use parent 'Test::Mocha::CalledOk';

sub is {
    # uncoverable pod
    my ( $class, $got, $exp ) = @_;
    return $got <= $exp;
}

sub stringify {
    # uncoverable pod
    my ( $class, $exp ) = @_;
    return "at most $exp time(s)";
}

1;
