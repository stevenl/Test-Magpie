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

my $file = __FILE__;
my @expect = (
    "once() called at $file line 12",
    "twice(1) called at $file line 13",
    "twice(1) called at $file line 13",
    "thrice(1) called at $file line 14",
    "thrice(2) called at $file line 14",
    "thrice(3) called at $file line 14",
);
is_deeply( \@got, \@expect, '... in the right order' );
