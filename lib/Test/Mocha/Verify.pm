package Test::Mocha::Verify;
# ABSTRACT: Mock wrapper to verify method calls

use strict;
use warnings;

use Test::Mocha::MethodCall;
use Test::Mocha::Types qw( Mock NumRange );
use Test::Mocha::Util qw( extract_method_name is_called );
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
    my $self = shift;

    my $method_call = Test::Mocha::MethodCall->new(
        invocant => $self->{mock},
        name     => extract_method_name($AUTOLOAD),
        args     => \@_,
    );
    is_called( $method_call, %$self );
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
    # uncoverable pod
    $AUTOLOAD = 'can';
    goto &AUTOLOAD;
}

# Don't let AUTOLOAD() handle DESTROY()
sub DESTROY { }

1;
