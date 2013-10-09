#!/usr/bin/perl -T
use strict;
use warnings;

use Test::More tests => 18;
use Test::Fatal;

BEGIN { use_ok 'Test::Mocha' }

use Scalar::Util      qw( blessed );
use Test::Mocha::Util qw( getattr );
use Types::Standard   qw( Int );

# ----------------------
# creating a mock
my $mock = mock();
ok $mock, 'mock() creates a simple mock';

# ----------------------
# mocks pretend to be anything you want
ok $mock->isa('Bar'),  'mock can isa(anything)';
ok $mock->does('Baz'), 'mock can does(anything)';
ok $mock->DOES('Baz'), 'mock can DOES(anything)';

# ----------------------
# mocks accept any methods call on them
my $calls   = getattr($mock, 'calls');
my $coderef = $mock->can('foo');
ok $coderef,                    'mock can(anything)';
is ref($coderef), 'CODE',       ' and can() returns a coderef';
is $coderef->($mock, 1), undef, ' and can() coderef returns undef by default';
is $calls->[-1]->as_string, 'foo(1)', ' and method call is recorded';

is $mock->foo(bar => 1), undef,
    'mock accepts any method call, returning undef by default';
is $calls->[-1]->as_string, 'foo(bar: 1)', ' and method call is recorded';

# ----------------------
# type constraints
my $e = exception { $mock->foo(1, Int) };
like $e, qr/Int/,
    'mock does not accept method call with type constraint argument';
like $e, qr/mock\.t/, ' and message traces back to this script';

is $mock->foo(1, mock), undef, 'mock as method argument not isa(Type::Tiny)';

# ----------------------
# calling mock with a ref
stub($mock)->ref->returns('Foo');
is $mock->ref, 'Foo', 'mock has a ref';
is ref($mock), 'Foo', ' and ref() returns the class';

TODO: {
    local $TODO = 'unimplemented';
    stub($mock)->blessed->returns('Foo');
    is blessed($mock), 'Foo', ' and blessed() returns the class';
}

$mock->DESTROY;
isnt $calls->[-1]->as_string, 'DESTROY()', 'DESTROY() is not AUTOLOADed';
