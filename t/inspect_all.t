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

like exception { inspect_all() },
    qr/^inspect_all\(\) must be given a mock object/,
    'no argument exception';
like exception { inspect_all('string') },
    qr/^inspect_all\(\) must be given a mock object/,
    'invalid argument exception';

my @all = inspect_all($mock);
isa_ok $all[0], 'Test::Mocha::MethodCall';
is @all, 6, 'inspect_all() returns all method calls';
my $file = __FILE__;
is_deeply \@all, [
    "once() called at $file line 11",
    "twice(1) called at $file line 12",
    "twice(1) called at $file line 12",
    "thrice(1) called at $file line 13",
    "thrice(2) called at $file line 13",
    "thrice(3) called at $file line 13",
], ' and in the right order';
