#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 6;
use Test::Fatal;

BEGIN { use_ok 'Test::Mocha' }

my $mock = mock;
$mock->once;
$mock->twice(1)   for 1..2;
$mock->thrice($_) for 1..3;

like(
    exception { inspect_all() },
    qr/^inspect_all\(\) must be given a mock object/,
    'no argument exception'
);

like(
    exception { inspect_all('string') },
    qr/^inspect_all\(\) must be given a mock object/,
    'invalid argument exception'
);

my @got = inspect_all($mock);

isa_ok( $got[0], 'Test::Mocha::MethodCall' );

is( @got, 6, 'inspect_all() returns all method calls' );

my @expect = qw(
    once()
    twice(1)
    twice(1)
    thrice(1)
    thrice(2)
    thrice(3)
);
is_deeply( \@got, \@expect, '... in the right order' );
