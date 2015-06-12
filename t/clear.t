#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 5;
use Test::Fatal;

use lib 't/lib';
use TestClass;

BEGIN { use_ok 'Test::Mocha' }

my $FILE = __FILE__;

my @mocks = ( mock, mock );
my @spies = ( spy( TestClass->new ), spy( TestClass->new ) );

foreach my $subj ( \@mocks, \@spies ) {
    subtest 'calls are cleared' => sub {
        my $calls1 = $subj->[0]->__calls;
        my $calls2 = $subj->[1]->__calls;

        $subj->[0]->set;
        $subj->[1]->get;
        is( ( @{$calls1} + @{$calls2} ),
            2, 'mock and spy have calls before clear()' );

        clear @$subj;
        is( ( @{$calls1} + @{$calls2} ), 0, '... and no calls after clear()' );
    };
}

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
