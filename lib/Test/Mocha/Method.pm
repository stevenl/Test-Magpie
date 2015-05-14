package Test::Mocha::Method;
# ABSTRACT: Objects to represent methods and their arguuments

use strict;
use warnings;

use Carp 'croak';
use Test::Mocha::PartialDump;
use Test::Mocha::Types qw( Matcher Slurpy );
use Test::Mocha::Util qw( check_slurpy_arg match );
use Types::Standard qw( ArrayRef HashRef Str );

use overload '""' => \&stringify, fallback => 1;

# cause string overloaded objects (Matchers) to be stringified
my $Dumper = Test::Mocha::PartialDump->new( objects => 0, stringify => 1 );

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
    my ($self) = @_;
    return $self->name . '(' . $Dumper->dump( $self->args ) . ')';
}

sub __satisfied_by {
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
    check_slurpy_arg(@expected);

    # match @input against @expected which may include argument matchers
    while ( @input && @expected ) {
        my $matcher = shift @expected;

        # slurpy argument matcher
        if ( Slurpy->check($matcher) ) {
            $matcher = $matcher->{slurpy};
            ### assert: $matcher->is_a_type_of(ArrayRef) || $matcher->is_a_type_of(HashRef)

            my $value;
            if ( $matcher->is_a_type_of(ArrayRef) ) {
                $value = [@input];
            }
            elsif ( $matcher->is_a_type_of(HashRef) ) {
                return unless scalar(@input) % 2 == 0;
                $value = {@input};
            }
            # else { invalid matcher type }
            return unless $matcher->check($value);

            @input = ();
        }
        # argument matcher
        elsif ( Matcher->check($matcher) ) {
            return unless $matcher->check( shift @input );
        }
        # literal match
        else {
            return unless match( shift(@input), $matcher );
        }
    }

    # slurpy matcher should handle empty argument lists
    if ( @expected > 0 && Slurpy->check( $expected[0] ) ) {
        my $matcher = shift(@expected)->{slurpy};

        my $value;
        if ( $matcher->is_a_type_of(ArrayRef) ) {
            $value = [@input];
        }
        elsif ( $matcher->is_a_type_of(HashRef) ) {
            return unless scalar(@input) % 2 == 0;
            $value = {@input};
        }
        # else { invalid matcher type }
        return unless $matcher->check($value);
    }

    return @input == 0 && @expected == 0;
}

1;
