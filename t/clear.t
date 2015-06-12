#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 4;
use Test::Fatal;

BEGIN { use_ok 'Test::Mocha' }

my $FILE = __FILE__;

my $mock1 = mock;
my $mock2 = mock;
my @mocks = ( $mock1, $mock2 );

subtest 'calls are cleared' => sub {
    my $calls1 = $mock1->__calls;
    my $calls2 = $mock2->__calls;

    $mock1->foo;
    $mock2->bar;
    is( ( @{$calls1} + @{$calls2} ), 2, 'mocks have calls before clear()' );

    clear @mocks;
    is( ( @{$calls1} + @{$calls2} ), 0, '... and no calls after clear()' );
};

# ----------------------
# exceptions

subtest 'throws if no arguments' => sub {
    like(
        my $e = exception { clear },
        qr/^clear\(\) must be given mock objects only/,
    );
    like( $e, qr/at \Q$FILE\E/, '... and error traces back to this script' );
};

subtest 'throws with invalid arguments' => sub {
    like(
        my $e = exception { clear 1 },
        qr/^clear\(\) must be given mock objects only/,
    );
    like( $e, qr/at \Q$FILE\E/, '... and error traces back to this script' );
};
