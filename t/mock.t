#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 12;

BEGIN { use_ok 'Test::Mocha' }

use Scalar::Util      qw( blessed );
use Test::Mocha::Util qw( getattr );

# ----------------------
# creating a mock

my $mock = mock();
ok( $mock, 'mock() creates a simple mock' );

# ----------------------
# mocks pretend to be anything you want

ok( $mock->isa('Bar'),  'mock can isa(anything)'  );
ok( $mock->does('Baz'), 'mock can does(anything)' );
ok( $mock->DOES('Baz'), 'mock can DOES(anything)' );

# ----------------------
# mocks accept any method calls

my $calls   = getattr($mock, 'calls');
my $coderef = $mock->can('foo');
ok( $coderef, 'mock can(anything)' );
is( ref($coderef), 'CODE', '... and can() returns a coderef' );
is(
    $coderef->($mock, 1), undef,
    '... and can() coderef returns undef by default'
);
is(
    $calls->[-1]->stringify_long,
    sprintf('foo(1) called at %s line %d', __FILE__, __LINE__ - 6),
    '... and method call is recorded'
);

is(
    $mock->foo(bar => 1), undef,
    'mock accepts any method call, returning undef by default'
);
is(
    $calls->[-1]->stringify_long,
    sprintf('foo(bar: 1) called at %s line %d', __FILE__, __LINE__ - 6),
    '... and method call is recorded'
);

$mock->DESTROY;
isnt(
    $calls->[-1]->stringify, 'DESTROY()',
    'DESTROY() is not AUTOLOADed'
);
