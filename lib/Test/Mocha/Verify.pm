package Test::Mocha::Verify;
# ABSTRACT: Verify interactions with a mock object by looking into its invocation history

use Moose;
use namespace::autoclean;

use aliased 'Test::Mocha::Invocation';

use Test::Builder;
use Test::Mocha::Types qw( NumRange );
use Test::Mocha::Util qw( extract_method_name get_attribute_value );
use Types::Standard qw( Num Str );

with 'Test::Mocha::Role::HasMock';

our $AUTOLOAD;

my $TB = Test::Builder->new;

has 'test_name' => (
    isa => Str,
    reader => '_test_name',
);

has 'times' => (
    isa => Num,
    reader => '_times',
);
has 'at_least' => (
    isa => Num,
    reader => '_at_least',
);
has 'at_most' => (
    isa => Num,
    reader => '_at_most',
);
has 'between' => (
    isa => NumRange,
    reader => '_between',
);

sub AUTOLOAD {
    my $self = shift;

    my $observe = Invocation->new(
        name => extract_method_name($AUTOLOAD),
        args => \@_,
    );

    my $mock  = get_attribute_value($self, 'mock');
    my $calls = get_attribute_value($mock, 'calls');

    my @calls = grep { $observe->satisfied_by($_) } @$calls;
    my $num_calls = scalar @calls;

    my $test_name = $self->_test_name;

    # uncoverable branch false count:4
    if (defined $self->_times) {
        $test_name = sprintf '%s was called %u time(s)',
            $observe->as_string, $self->_times
                unless defined $test_name;
        $TB->is_num( $num_calls, $self->_times, $test_name );
    }
    elsif (defined $self->_at_least) {
        $test_name = sprintf '%s was called at least %u time(s)',
            $observe->as_string, $self->_at_least
                unless defined $test_name;
        $TB->cmp_ok( $num_calls, '>=', $self->_at_least, $test_name );
    }
    elsif (defined $self->_at_most) {
        $test_name = sprintf '%s was called at most %u time(s)',
            $observe->as_string, $self->_at_most
                unless defined $test_name;
        $TB->cmp_ok( $num_calls, '<=', $self->_at_most, $test_name );
    }
    elsif (defined $self->_between) {
        my ($lower, $upper) = @{$self->_between};
        $test_name = sprintf '%s was called between %u and %u time(s)',
            $observe->as_string, $lower, $upper
                unless defined $test_name;
        $TB->ok( $lower <= $num_calls && $num_calls <= $upper, $test_name );
    }
    return @calls;
}

__PACKAGE__->meta->make_immutable;
1;
