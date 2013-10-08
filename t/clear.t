#!/usr/bin/perl -T
use strict;
use warnings;

use Test::More tests => 6;
use Test::Fatal;

BEGIN { use_ok 'Test::Mocha' }

use Test::Mocha::Util qw( get_attribute_value );

my $mock  = mock;
my $calls = get_attribute_value($mock, 'calls');

clear($mock);
is scalar(@$calls), 0, 'clear() with no calls';

$mock->foo;
$mock->bar;
is scalar(@$calls), 2, 'mock has calls';

clear($mock);
is scalar(@$calls), 0, 'mock has no calls after clear()';

# ----------------------
# exceptions

ok exception { clear() },  'clear() must be given an argument';
ok exception { clear(1) }, ' and argument must be a mock';
