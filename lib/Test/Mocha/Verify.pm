package Test::Mocha::Verify;
# ABSTRACT: Mock wrapper to verify method calls

use strict;
use warnings;

use Test::Builder;
use Test::Mocha::MethodCall;
use Test::Mocha::Types qw( Mock NumRange );
use Test::Mocha::Util  qw( extract_method_name get_attribute_value );
use Types::Standard    qw( Num Str );

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

# Private methods are implemented as anonymous subs to keep the
# namespace clear for AUTOLOAD to handle as much as possible.

my $ok = sub {
    my ($test_ok, $method_call, $exp, $test_name) = @_;

    $test_name = sprintf '%s was called %s time(s)', $method_call, $exp
        unless defined $test_name;

    # Test failure report should not trace back to Mocha modules
    local $Test::Builder::Level = 2;

    $TB->ok( $test_ok, $test_name );
    return;
};

my $diag = sub {
    my ($method_call, $got, $exp, $all_calls) = @_;

    return if $TB->in_todo;

    my $out
      = "Error: unexpected number of calls to '$method_call'\n"
      . "         got: $got time(s)\n"
      . "    expected: $exp time(s)\n"
      . "Complete method call history (most recent call last):\n";

    if ( defined $all_calls ) {
        $out .= "    $_\n" foreach @$all_calls;
    }
    else {
        $out .= "    (No methods were called)\n";
    }
    $TB->diag($out);

    return;
};

sub AUTOLOAD {
    my $self = shift;

    my $call_to_verify = Test::Mocha::MethodCall->new(
        name => extract_method_name($AUTOLOAD),
        args => \@_,
    );

    my $mock  = get_attribute_value($self, 'mock');
    my $calls = get_attribute_value($mock, 'calls');

    my $got = grep { $call_to_verify->satisfied_by($_) } @$calls;
    my $exp;
    my $test_ok;

    # uncoverable branch false count:4
    if ( defined $self->{times} ) {
        $exp = $self->{times};
        $test_ok = $got == $self->{times};
    }
    elsif ( defined $self->{at_least} ) {
        $exp = "at least $self->{at_least}";
        $test_ok = $got >= $self->{at_least};
    }
    elsif ( defined $self->{at_most} ) {
        $exp = "at most $self->{at_most}";
        $test_ok = $got <= $self->{at_most};
    }
    elsif ( defined $self->{between} ) {
        my ($lower, $upper) = @{ $self->{between} };
        $exp = "between $lower and $upper";
        $test_ok = $lower <= $got && $got <= $upper;
    }

    $ok->( $test_ok, $call_to_verify->as_string, $exp, $self->{test_name} );
    $diag->( $call_to_verify->as_string, $got, $exp, $calls )
        unless $test_ok;

    return;
}

# Don't let AUTOLOAD() handle DESTROY()
sub DESTROY { }

1;
