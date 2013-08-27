package Test::Mocha::Inspect;
# ABSTRACT: Inspect method calls on mock objects

use strict;
use warnings;

use Test::Mocha::MethodCall;
use Test::Mocha::Types qw( Mock );
use Test::Mocha::Util qw( extract_method_name get_attribute_value );

our $AUTOLOAD;

sub new {
    # uncoverable pod
    my ($class, %args) = @_;
    ### assert: defined $args{mock} && Mock->check( $args{mock} )
    return bless \%args, $class;
}

sub AUTOLOAD {
    my $self = shift;

    my $inspect = Test::Mocha::MethodCall->new(
        name => extract_method_name($AUTOLOAD),
        args => \@_,
    );

    my $mock  = get_attribute_value($self, 'mock');
    my $calls = get_attribute_value($mock, 'calls');

    return grep { $inspect->satisfied_by($_) } @$calls;
}

1;
