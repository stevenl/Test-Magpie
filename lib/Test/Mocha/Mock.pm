package Test::Mocha::Mock;
# ABSTRACT: Mock objects

use Moose;
use namespace::autoclean;

use aliased 'Test::Mocha::Invocation';
use aliased 'Test::Mocha::Stub';

use Test::Mocha::Util qw(
    extract_method_name
    get_attribute_value
    has_caller_package
);

use Types::Standard qw( ArrayRef InstanceOf Int Map Str );
use UNIVERSAL::ref;

our $AUTOLOAD;

# class
# The name of the class that the object is pretending to be blessed into.
# Calling C<ref()> on the mock object (either as a method or as a function)
# will return this class name.

has 'class' => (
    isa => Str,
    reader => 'ref',
    default => __PACKAGE__,
);

# calls
# An array reference containing a record of all methods called on this mock
# to be used for verification.

has 'calls' => (
    isa => ArrayRef[InstanceOf[Invocation]],
    is => 'bare',
    default => sub { [] }
);

# stubs
# Contains all of the methods stubbed for this mock. It maps the method name
# to an array of stubs. Stubs are matched against invocation arguments to
# determine which stub to dispatch to.

has 'stubs' => (
    isa => Map[ Str, ArrayRef[InstanceOf[Stub]] ],
    is => 'bare',
    default => sub { {} }
);

sub AUTOLOAD {
    my $self = shift;
    my $method_name = extract_method_name($AUTOLOAD);

    # record the method call for verification
    my $method_call = Invocation->new(
        name => $method_name,
        args => \@_,
    );

    my $calls = get_attribute_value($self, 'calls');
    my $stubs = get_attribute_value($self, 'stubs');

    push @$calls, $method_call;

    # find a stub to return a response
    if (defined $stubs->{$method_name}) {
        foreach my $stub ( @{$stubs->{$method_name}} ) {
            return $stub->execute
                if $stub->satisfied_by($method_call);
        }
    }
    return;
}

# isa()
# Always returns true. It allows the mock object to C<isa()> any class that
# is required.

sub isa {
    return if has_caller_package('UNIVERSAL::ref');
    return 1;
}

# does()
# Always returns true. It allows the mock object to C<does()> any role that
# is required.

sub does {
    return if has_caller_package('UNIVERSAL::ref');
    return 1;
}

# can()
# Always returns a reference to the C<AUTOLOAD()> method. It allows the mock
# object to C<can()> do any method that is required.

sub can {
    my ($self, $method_name) = @_;
    return sub {
        $AUTOLOAD = $method_name;
        goto &AUTOLOAD;
    };
}

__PACKAGE__->meta->make_immutable;
1;
