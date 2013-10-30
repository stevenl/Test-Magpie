#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 17;
use Test::Fatal;
use Types::Standard qw( Int slurpy );

BEGIN { use_ok 'Test::Mocha' }

my $mock = mock;
$mock->once;
$mock->twice(1)   for 1..2;
$mock->thrice($_) for 1..3;

# inspect() argument checks
like(
    exception { inspect() },
    qr/^inspect\(\) must be given a coderef/,
    'no argument exception'
);
like(
    exception { inspect('string') },
    qr/^inspect\(\) must be given a coderef/,
    'invalid argument exception'
);

my $file = __FILE__;
my ( $once ) = inspect( sub { $mock->once } );
isa_ok( $once, 'Test::Mocha::MethodCall' );
is(
    $once, "once() called at $file line 13",
    'inspect() returns method call'
);

my @twice = inspect( sub { $mock->twice(1) } );
is( @twice, 2, 'inspect() with argument returns method call' );
isa_ok( $twice[0], 'Test::Mocha::MethodCall' );
is(
    $twice[0], "twice(1) called at $file line 14",
    '... and method call stringifies'
);

my @thrice = inspect( sub { $mock->thrice(Int) } );
is( @thrice, 3, 'inspect() works with argument matcher' );
isa_ok( $thrice[0], 'Test::Mocha::MethodCall' );
is_deeply(
    \@thrice, [
        "thrice(1) called at $file line 15",
        "thrice(2) called at $file line 15",
        "thrice(3) called at $file line 15",
    ],
    '... and returns calls in the right order'
);

# ----------------------
# inspect() with type constraint arguments

@thrice = inspect( sub { $mock->thrice(SlurpyArray) } );
is( @thrice, 3, 'inspect() works with slurpy argument matcher' );

my $e = exception { inspect( sub { $mock->twice(SlurpyArray, 1) } ) };
like(
    $e, qr/^No arguments allowed after a slurpy type constraint/,
    'Disallow arguments after a slurpy type constraint'
);
like( $e, qr/inspect\.t/, '... and message traces back to this script' );

$e = exception { inspect( sub { $mock->twice(slurpy Int) } ) };
like(
    $e, qr/^Slurpy argument must be a type of ArrayRef or HashRef/,
    'Invalid Slurpy argument'
);
like( $e, qr/inspect\.t/, '... and message traces back to this script' );

is( inspect( sub { $mock->DESTROY } ), undef, 'DESTROY() is not AUTOLOADed' );
