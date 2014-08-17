package Test::Mocha::CalledOk::Times;

use strict;
use warnings;
use parent 'Test::Mocha::CalledOk';

#sub new {
#    my $self = shift->SUPER::new(@_);
#
#    # provide a default test_name
#    $self->{test_name} ||=
#      sprintf '%s was called %s time(s)', $self->method_call, $self->times;
#
#    return $self;
#}
#
#sub times {
#    my ($self) = @_;
#    ### assert: defined $self->{times} && Num->check( $self->{times} )
#    return $self->{times};
#}

sub is {
    my ( $class, $got, $exp ) = @_;
    return $got == $exp;
}

sub stringify {
    my ( $class, $exp ) = @_;
    return "$exp time(s)";
}

1;
