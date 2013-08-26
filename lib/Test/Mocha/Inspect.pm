package Test::Mocha::Inspect;
# ABSTRACT: Inspect method calls on mock objects

use strict;
use warnings;
use feature 'state';

use List::Util qw( first );
use Test::Mocha::MethodCall;
use Test::Mocha::Types qw( MockWrapper );
use Test::Mocha::Util qw( extract_method_name get_attribute_value );
use Type::Params qw( compile );
use Types::Standard qw( ClassName slurpy );

our $AUTOLOAD;

sub new {
    state $check = compile( ClassName, slurpy MockWrapper );
    my ($class, $self) = $check->(@_);

    return bless $self, $class;
}

sub AUTOLOAD {
    my $self = shift;

    my $inspect = Test::Mocha::MethodCall->new(
        name => extract_method_name($AUTOLOAD),
        args => \@_,
    );

    my $mock  = get_attribute_value($self, 'mock');
    my $calls = get_attribute_value($mock, 'calls');

    return first { $inspect->satisfied_by($_) } @$calls;
}

1;
