#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 6;
use Test::Fatal;

BEGIN { use_ok 'Test::Mocha' }

use Test::Mocha::Util qw( getattr );

my $mock1 = mock;
my $mock2 = mock;
my @mocks = ($mock1, $mock2);

my $calls1 = getattr($mock1, 'calls');
my $calls2 = getattr($mock2, 'calls');

$mock1->foo;
$mock2->bar;
is( (@$calls1 + @$calls2), 2, 'mocks have calls before clear()' );

clear(@mocks);
is( (@$calls1 + @$calls2), 0, '... and no calls after clear()' );

# ----------------------
# exceptions

ok exception { clear() },  'clear() must be given an argument';
ok exception { clear(1) }, '... and argument must be a mock';

# ----------------------
# Miscellaneous test to cover Test::Mocha::Util::getattr

like exception { getattr($mock1, 'notexists') },
    qr/^Attribute \'notexists\' does not exist for object/,
    'getattr() throws for non-existent attribute';
