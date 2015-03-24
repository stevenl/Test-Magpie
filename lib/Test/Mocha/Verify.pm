package Test::Mocha::Verify;
# ABSTRACT: Mock wrapper to verify method calls (DEPRECATED)

use strict;
use warnings;

use Test::Mocha::MethodCall;
use Test::Mocha::Types qw( Mock NumRange );
use Test::Mocha::Util qw( extract_method_name has_caller_package is_called );
use Types::Standard qw( Num Str );

our $AUTOLOAD;

sub new {
    # uncoverable pod
    my ( $class, %args ) = @_;

    ### assert: defined $args{mock} && Mock->check( $args{mock} )
    ### assert: !defined $args{ test_name } || Str->check( $args{ test_name } )
    ### assert: !defined $args{ times     } || Num->check( $args{ times     } )
    ### assert: !defined $args{ at_least  } || Num->check( $args{ at_least  } )
    ### assert: !defined $args{ at_most   } || Num->check( $args{ at_most   } )
    ### assert: !defined $args{ between   } || NumRange->check( $args{between} )
    ### assert: 1 == grep { defined } @args{ times at_least at_most between }

    return bless \%args, $class;
}

sub AUTOLOAD {
    my ( $self, @args ) = @_;

    my $method_call = Test::Mocha::MethodCall->new(
        invocant => $self->{mock},
        name     => extract_method_name($AUTOLOAD),
        args     => \@args,
    );

    my ($class) =
      grep { defined $self->{$_} } qw{ times at_least at_most between };
    my %options = (
        times    => 'Test::Mocha::CalledOk::Times',
        at_least => 'Test::Mocha::CalledOk::AtLeast',
        at_most  => 'Test::Mocha::CalledOk::AtMost',
        between  => 'Test::Mocha::CalledOk::Between',
    );

    $options{$class}->test( $method_call, $self->{$class}, $self->{test_name} );
    return;
}

# Let AUTOLOAD() handle the UNIVERSAL methods

sub isa {
    # uncoverable pod
    $AUTOLOAD = 'isa';
    goto &AUTOLOAD;
}

sub DOES {
    # uncoverable pod
    $AUTOLOAD = 'DOES';
    goto &AUTOLOAD;
}

sub can {
    # Handle can('CARP_TRACE') for internal croak()'s (Carp v1.32+)
    # uncoverable pod
    return if has_caller_package(__PACKAGE__);

    $AUTOLOAD = 'can';
    goto &AUTOLOAD;
}

# Don't let AUTOLOAD() handle DESTROY() so that object can be destroyed
sub DESTROY { }

1;
