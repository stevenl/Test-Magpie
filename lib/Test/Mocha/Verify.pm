package Test::Mocha::Verify;
# ABSTRACT: Verify interactions with a mock object

use strict;
use warnings;

use Test::Builder;
use Test::Mocha::MethodCall;
use Test::Mocha::Types qw( Mock NumRange );
use Test::Mocha::Util qw( extract_method_name get_attribute_value );
use Types::Standard qw( Num Str );

our $AUTOLOAD;

my $TB = Test::Builder->new;

sub new {
    # uncoverable pod
    my ($class, %args) = @_;

    ### assert: defined $args{mock} && Mock->check( $args{mock} )
    ### assert: !defined $args{ name     } || Str->check( $args{ name     } )
    ### assert: !defined $args{ times    } || Num->check( $args{ times    } )
    ### assert: !defined $args{ at_least } || Num->check( $args{ at_least } )
    ### assert: !defined $args{ at_most  } || Num->check( $args{ at_most  } )
    ### assert: !defined $args{ between  } || NumRange->check( $args{between} )
    ### assert: 1 == grep { defined } @args{ times at_least at_most between }

    return bless \%args, $class;
}

sub AUTOLOAD {
    my $self = shift;

    my $observe = Test::Mocha::MethodCall->new(
        name => extract_method_name($AUTOLOAD),
        args => \@_,
    );

    my $mock  = get_attribute_value($self, 'mock');
    my $calls = get_attribute_value($mock, 'calls');

    my $num_calls = grep { $observe->satisfied_by($_) } @$calls;

    my $test_name = $self->{test_name};

    # uncoverable branch false count:4
    if (defined $self->{times}) {
        $test_name = sprintf '%s was called %u time(s)',
            $observe->as_string, $self->{times}
                unless defined $test_name;
        $TB->is_num( $num_calls, $self->{times}, $test_name );
    }
    elsif (defined $self->{at_least}) {
        $test_name = sprintf '%s was called at least %u time(s)',
            $observe->as_string, $self->{at_least}
                unless defined $test_name;
        $TB->cmp_ok( $num_calls, '>=', $self->{at_least}, $test_name );
    }
    elsif (defined $self->{at_most}) {
        $test_name = sprintf '%s was called at most %u time(s)',
            $observe->as_string, $self->{at_most}
                unless defined $test_name;
        $TB->cmp_ok( $num_calls, '<=', $self->{at_most}, $test_name );
    }
    elsif (defined $self->{between}) {
        my ($lower, $upper) = @{ $self->{between} };
        $test_name = sprintf '%s was called between %u and %u time(s)',
            $observe->as_string, $lower, $upper
                unless defined $test_name;
        $TB->ok( $lower <= $num_calls && $num_calls <= $upper, $test_name );
    }
    return;
}

1;
