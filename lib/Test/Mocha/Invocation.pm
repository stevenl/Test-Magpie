package Test::Mocha::Invocation;
# ABSTRACT: Represents an invocation of a method

use Moose;
use namespace::autoclean;

with 'Test::Mocha::Role::MethodCall';

__PACKAGE__->meta->make_immutable;
1;

=head1 DESCRIPTION

An invocation of a method on a mock object

=attr name

Returns the name of the method invoked.

=attr args

Returns a list of all arguments passed to the method call.

=cut
