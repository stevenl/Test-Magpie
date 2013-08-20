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
    my ($self) = @_;
    return $self->name . '(' . $Dumper->dump($self->args) . ')';
}

# Returns true if the given C<$invocation> would satisfy this method call.

sub satisfied_by {
    my ($self, $invocation) = @_;

    return unless $invocation->name eq $self->name;

    my @expected = $self->args;
    my @input    = $invocation->args;
    # invocation arguments can't be argument matchers
    ### assert: ! grep { Matcher->check($_) } @input

    while (@input && @expected) {
        my $matcher = shift @expected;

        if (Slurpy->check($matcher)) {
            croak 'No arguments allowed after a slurpy type constraint'
                unless @expected == 0;

            $matcher = $matcher->{slurpy};
            my $value;
            if ( $matcher->is_a_type_of(ArrayRef) ) {
                $value = [ @input ];
            }
            elsif ( $matcher->is_a_type_of(HashRef) ) {
                return unless scalar(@input) % 2 == 0;
                $value = { @input };
            }
            else {
                croak('Slurpy argument must be a type of ArrayRef or HashRef');
            }

            return unless $matcher->check($value);
            @input = ();
        }
        elsif (Matcher->check($matcher)) {
            return unless $matcher->check(shift @input);
        }
        else {
            return unless match(shift(@input), $matcher);
        }
    }
    return @input == 0 && @expected == 0;
}

1;
