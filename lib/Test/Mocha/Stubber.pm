package Test::Mocha::Stubber;
# ABSTRACT: Create methods stubs for mock objects

use Moose;
use namespace::autoclean;

use aliased 'Test::Mocha::Stub';
use Test::Mocha::Util qw( extract_method_name get_attribute_value );

with 'Test::Mocha::Role::HasMock';

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    my $method_name = extract_method_name($AUTOLOAD);

    my $stub = Stub->new(
        name => $method_name,
        args => \@_,
    );

    my $mock  = get_attribute_value($self, 'mock');
    my $stubs = get_attribute_value($mock, 'stubs');

    # add new stub to front of queue so that it takes precedence
    # over existing stubs that would satisfy the same invocations
    unshift @{ $stubs->{$method_name} }, $stub;

    return $stub;
}

__PACKAGE__->meta->make_immutable;
1;
