package Test::Magpie::ArgumentMatcher;
# ABSTRACT: Various templates to catch arguments

use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [qw( anything )],
};

sub anything {
    bless sub { return (1,()) }, __PACKAGE__;
}

sub match {
    my ($self, @input) = @_;
    return $self->(@input);
}

1;

=head1 SYNOPSIS

    use Test::Magpie::ArgumentMatcher qw( anything );
    use Test::Magpie qw( mock verify );

    my $mock = mock;
    $mock->push( button => 'red' );

    verify($mock)->push(anything);

=head1 DESCRIPTION

Argument matchers allow you to be more general in your specification to stubs
and verification. An argument matcher is an object that takes all remaining
paremeters of an invocation, consumes 1 or more, and returns the remaining
arguments back. At verification time, a invocation is verified if all arguments
have been consumed by all argument matchers.

An argument matcher may return C<undef> if the argument does not pass
validation.

=head2 Custom argument validators

An argument validator is just a subroutine that is blessed as
C<Test::Magpie::ArgumentMatcher>. You are welcome to subclass this package if
you wish to use a different storage system (like a traditional hash-reference),
though a single sub routine is normally all you will need.

=head2 Default argument matchers

This module provides a set of common argument matchers, and will probably handle
most of your needs. They are all available for import by name.

=func anything

Consumes all remaining arguments (even 0) and returns none. This effectively
slurps in any remaining arguments and considers them valid. Note, as this
consumes I<all> arguments, you cannot use further argument validators after this
one. You are, however, welcome to use them before.

=method match @in

Match an argument matcher against @in, and return a list of parameters still to
be consumed, or undef on validation.

=cut