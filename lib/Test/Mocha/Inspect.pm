package Test::Mocha::Inspect;
# ABSTRACT: Mock wrapper to inspect method calls

use strict;
use warnings;

use Test::Mocha::Method;
use Test::Mocha::Types 'Mock';
use Test::Mocha::Util qw( extract_method_name );

our $AUTOLOAD;

sub __new {
    # uncoverable pod
    my ( $class, %args ) = @_;
    ### assert: defined $args{mock} && Mock->check( $args{mock} )
    return bless \%args, $class;
}

sub __mock {
    my ($self) = @_;
    return $self->{mock};
}

sub AUTOLOAD {
    my ( $self, @args ) = @_;

    my $inspect = Test::Mocha::Method->new(
        name => extract_method_name($AUTOLOAD),
        args => \@args,
    );
    return grep { $inspect->satisfied_by($_) } @{ $self->__mock->__calls };
}

# Don't let AUTOLOAD() handle DESTROY() so that object can be destroyed
sub DESTROY { }

1;
