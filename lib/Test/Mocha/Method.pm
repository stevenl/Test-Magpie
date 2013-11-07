package Test::Mocha::Method;
# ABSTRACT: Objects to represent methods and their arguuments

use strict;
use warnings;

use Carp qw( croak );
use Test::Mocha::PartialDump;
use Test::Mocha::Types qw( Matcher Slurpy );
use Test::Mocha::Util  qw( match );
use Types::Standard    qw( ArrayRef HashRef Str );

use overload '""' => \&stringify, fallback => 1;

# croak() messages should not trace back to Mocha modules
our @CARP_NOT = qw(
    Test::Mocha::Inspect
    Test::Mocha::Mock
    Test::Mocha::Verify
);

# cause string overloaded objects (Matchers) to be stringified
my $Dumper = Test::Mocha::PartialDump->new(objects => 0, stringify => 1);

sub new {
    # uncoverable pod
    my ( $class, %args ) = @_;
    ### assert: Str->check( $args{name} )
    ### assert: ArrayRef->check( $args{args} )
    return bless \%args, $class;
}

sub name {
    # uncoverable pod
    return $_[0]->{name};
}

sub args {
    # uncoverable pod
    return @{ $_[0]->{args} };
}

sub stringify {
    # """
    # Stringifies this method call to something that roughly resembles what
    # you'd type in Perl.
    # """
    # uncoverable pod
    my ( $self ) = @_;
    return $self->name . '(' . $Dumper->dump($self->args) . ')';
}

my $slurp = sub {
    # """check slurpy arguments"""
    my ( $slurpy_matcher, @to_match ) = @_;

    ### assert: Slurpy->check($slurpy_matcher)
    my $matcher = $slurpy_matcher->{slurpy};

    my $value;
    if ( $matcher->is_a_type_of(ArrayRef) ) {
        $value = [ @to_match ];
    }
    elsif ( $matcher->is_a_type_of(HashRef) ) {
        return unless scalar(@to_match) % 2 == 0;
        $value = { @to_match };
    }
    else {
        croak('Slurpy argument must be a type of ArrayRef or HashRef');
    }

    return $matcher->check($value);
};

sub satisfied_by {
    # """
    # Returns true if the given C<$invocation> satisfies this method call.
    # """
    # uncoverable pod
    my ( $self, $invocation ) = @_;

    return unless $invocation->name eq $self->name;

    my @expected = $self->args;
    my @input    = $invocation->args;
    # invocation arguments can't be argument matchers
    ### assert: ! grep { Matcher->check($_) } @input

    while ( @input && @expected ) {
        my $matcher = shift @expected;

        if ( Slurpy->check($matcher) ) {
            croak 'No arguments allowed after a slurpy type constraint'
                unless @expected == 0;

            return unless $slurp->( $matcher, @input );

            @input = ();
        }
        elsif ( Matcher->check($matcher) ) {
            return unless $matcher->check( shift @input );
        }
        else {
            return unless match( shift(@input), $matcher );
        }
    }

    # slurpy matcher should handle empty argument lists
    if ( @expected > 0 && Slurpy->check($expected[0]) ) {
        my $matcher = shift @expected;

        croak 'No arguments allowed after a slurpy type constraint'
            unless @expected == 0;

        # uncoverable branch true
        return unless $slurp->( $matcher, @input );
    }

    return @input == 0 && @expected == 0;
}

1;
