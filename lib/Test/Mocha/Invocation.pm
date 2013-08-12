package Test::Mocha::Invocation;
# ABSTRACT: Represents a method call

use Moose;
use namespace::autoclean;

with 'Test::Mocha::Role::MethodCall';

__PACKAGE__->meta->make_immutable;
1;
