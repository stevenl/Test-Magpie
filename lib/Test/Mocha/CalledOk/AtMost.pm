package Test::Mocha::CalledOk::AtMost;

use strict;
use warnings;
use parent 'Test::Mocha::CalledOk';

sub is {
    my ( $class, $got, $exp ) = @_;
    return $got <= $exp;
}

sub stringify {
    my ( $class, $exp ) = @_;
    return "at most $exp time(s)";
}

1;
