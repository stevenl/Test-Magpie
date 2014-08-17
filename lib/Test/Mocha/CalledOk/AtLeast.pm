package Test::Mocha::CalledOk::AtLeast;

use strict;
use warnings;
use parent 'Test::Mocha::CalledOk';

sub is {
    my ( $class, $got, $exp ) = @_;
    return $got >= $exp;
}

sub stringify {
    my ( $class, $exp ) = @_;
    return "at least $exp time(s)";
}

1;
