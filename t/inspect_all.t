#!/usr/bin/perl -T
use strict;
use warnings;

use Test::More tests => 5;
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
is @all, 6, 'inspect_all() returns all method calls';
is_deeply \@all, [qw(
    once()
    twice(1)
    twice(1)
    thrice(1)
    thrice(2)
    thrice(3)
)], ' and in the right order';
