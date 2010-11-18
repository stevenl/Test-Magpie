package Test::Magpie::Mock;
# ABSTRACT: A mock object
use Moose -metaclass => 'Test::Magpie::Meta::Class';

use Sub::Exporter -setup => {
    exports => [qw( add_stub )],
};

use aliased 'Test::Magpie::Invocation';

use Test::Magpie::Util qw( extract_method_name );
use List::AllUtils qw( first );
use MooseX::Types::Moose qw( ArrayRef Int Object Str );
use MooseX::Types::Structured qw( Map );
use Moose::Util qw( find_meta );
use Test::Builder;

has 'invocations' => (
    isa => ArrayRef,
    is => 'bare',
    default => sub { [] }
);

has 'stubs' => (
    isa => Map[Str, Object],
    is => 'bare',
    default => sub { {} }
);

our $AUTOLOAD;

sub AUTOLOAD {
    my $method = $AUTOLOAD;
    my $self = shift;
    my $meta = find_meta($self);
    my $invocations = $meta->find_attribute_by_name('invocations')
        ->get_value($self);
    my $invocation = Invocation->new(
        method_name => extract_method_name($method),
        arguments => \@_
    );

    push @$invocations, $invocation;

    if(my $stubs = $meta->find_attribute_by_name('stubs')->get_value($self)->{
        $invocation->method_name
    }) {
        my $stub = first { $_->satisfied_by($invocation) } @$stubs;
        return unless $stub;
        $stub->execute;
    }
}

sub add_stub {
    my ($self, $stub) = @_;
    my $meta = find_meta($self);
    my $stubs = $meta->find_attribute_by_name('stubs')->get_value($self);
    my $method = $stub->method_name;
    $stubs->{$method} ||= [];
    push @{ $stubs->{$method} }, $stub;
}

sub does { 1 }
sub isa {
    my ($self, $package) = @_;
    return !($package =~ /^Class::MOP::*/);
}

1;

=head1 DESCRIPTION

Mock objects are the objects you pass around as if they were real objects. They
do not have a defined API; any method call is valid. A mock on its own is in
record mode - method calls and arguments will be saved. You can switch
temporarily to stub and verification mode with C<when> and C<verify> in
L<Test::Magpie>, respectively.

=attr stubs

This attribute is internal, and not publically accessible.

Returns a map of method name to stub array references. Stubs are matched against
invocation arguments to determine which stub to dispatch to.

=attr invocations

This attribute is internal, and not publically accessible.

Returns an array reference of all method invocations on this mock.

=method isa $class

Forced to return true for any package

=method does $role

Forced to return true for any role

=cut