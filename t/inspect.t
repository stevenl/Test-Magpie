#!/usr/bin/perl -T
use strict;
use warnings;

use Test::More tests => 16;
use Test::Fatal;
use Types::Standard qw( ArrayRef Int slurpy );

BEGIN { use_ok 'Test::Mocha' }

my $mock = mock;
$mock->once;
$mock->twice(1)   for 1..2;
$mock->thrice($_) for 1..3;

# inspect() argument checks
like exception { inspect() },
    qr/^inspect\(\) must be given a mock object/,
    'no argument exception';
like exception { inspect('string') },
    qr/^inspect\(\) must be given a mock object/,
    'invalid argument exception';

my ($once) = inspect($mock)->once;
is $once, 'once()', 'inspect() returns method call';

my @twice = inspect($mock)->twice(1);
is @twice, 2, 'inspect() with argument returns method call';
is $twice[0], 'twice(1)', ' and method call stringifies';

my @thrice = inspect($mock)->thrice(Int);
is @thrice, 3, 'inspect() works with argument matcher';
is $thrice[0], 'thrice(1)', ' and returns calls in the right order';
is $thrice[1], 'thrice(2)';
is $thrice[2], 'thrice(3)';

# ----------------------
# inspect() with type constraint arguments

@thrice = inspect($mock)->thrice(slurpy ArrayRef);
is @thrice, 3, 'inspect() works with slurpy argument matcher';

my $e = exception { inspect($mock)->twice(slurpy ArrayRef, 1) };
like $e, qr/^No arguments allowed after a slurpy type constraint/,
    'Disallow arguments after a slurpy type constraint';
like $e, qr/inspect\.t/, ' and message traces back to this script';

$e = exception { inspect($mock)->twice(slurpy Int) };
like $e, qr/^Slurpy argument must be a type of ArrayRef or HashRef/,
    'Invalid Slurpy argument';
like $e, qr/inspect\.t/, ' and message traces back to this script';

is inspect($mock)->DESTROY, undef, 'DESTROY() is not AUTOLOADed';
