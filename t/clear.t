#!/usr/bin/perl -T
use strict;
use warnings;

use Test::More tests => 7;
use Test::Fatal;

BEGIN { use_ok 'Test::Mocha' }

use Test::Mocha::Util qw( getattr );

my $mock  = mock;
my $calls = getattr($mock, 'calls');

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

# ----------------------
# Miscellaneous test to cover Test::Mocha::Util::getattr

like exception { getattr($mock, 'notexists') },
    qr/^Attribute \'notexists\' does not exist for object/,
    'getattr() throws for non-existent attribute';
