package Test::Mocha::CalledOk::Between;

use strict;
use warnings;
use parent 'Test::Mocha::CalledOk';

sub is {
    my ( $class, $got, $exp ) = @_;
    return $exp->[0] <= $got && $got <= $exp->[1];
}

sub stringify {
    my ( $class, $exp ) = @_;
    return "between $exp->[0] and $exp->[1] time(s)";
}

1;
