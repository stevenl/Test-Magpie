package Test::Mocha::Role::MethodCall;
# ABSTRACT: A role that represents a method call

use Moose::Role;
use namespace::autoclean;

use Carp qw( croak );
use Devel::PartialDump;
use Test::Mocha::Types qw( Matcher Slurpy );
use Test::Mocha::Util qw( match );
use Types::Standard qw( ArrayRef HashRef Str );

our @CARP_NOT = qw( Test::Mocha::Verify );

# cause string overloaded objects (Matchers) to be stringified
my $Dumper = Devel::PartialDump->new(objects => 0, stringify => 1);

has 'name' => (
    isa => Str,
    is  => 'ro',
    required => 1
);

has 'args' => (
    isa     => ArrayRef,
    traits  => ['Array'],
    handles => { args => 'elements' },
    default => sub { [] },
);

# Stringifies this method call to something that roughly resembles what you'd
# type in Perl.

sub as_string {
    # uncoverable pod
    my ($self) = @_;
    return $self->name . '(' . $Dumper->dump($self->args) . ')';
}

my $slurp = sub {
    my ($slurpy_matcher, @to_match) = @_;

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

# Returns true if the given C<$invocation> would satisfy this method call.

sub satisfied_by {
    # uncoverable pod
    my ($self, $invocation) = @_;

    return unless $invocation->name eq $self->name;

    my @expected = $self->args;
    my @input    = $invocation->args;
    # invocation arguments can't be argument matchers
    ### assert: ! grep { Matcher->check($_) } @input

    while (@input && @expected) {
        my $matcher = shift @expected;

        if ( Slurpy->check($matcher) ) {
            croak 'No arguments allowed after a slurpy type constraint'
                unless @expected == 0;

            return unless $slurp->($matcher, @input);

            @input = ();
        }
        elsif (Matcher->check($matcher)) {
            return unless $matcher->check(shift @input);
        }
        else {
            return unless match(shift(@input), $matcher);
        }
    }

    # slurpy matcher do handle empty argument lists
    if (@expected > 0) {
        if ( Slurpy->check($expected[0]) ) {
            my $matcher = shift @expected;
            croak 'No arguments allowed after a slurpy type constraint'
                unless @expected == 0;

            return unless $slurp->($matcher, @input);
        }
    }

    return @input == 0 && @expected == 0;
}

1;
