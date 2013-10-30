#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 5;
use Test::Fatal;
use Type::Utils -all;
use Types::Standard qw( Int );

BEGIN { use_ok 'Test::Mocha' }

subtest 'Lets verify some behaviour!' => sub {
    my $mocked_list = mock;

    $mocked_list->add('one');
    $mocked_list->clear;

    called_ok( sub { $mocked_list->add('one') } );
    called_ok( sub { $mocked_list->clear } );
};

subtest 'How about some stubbing?' => sub {
    my $mocked_list = mock;

    stub( sub { $mocked_list->get(0) } )->returns('first');
    stub( sub { $mocked_list->get(1) } )->throws('Kaboom!');

    is( $mocked_list->get(0) => 'first' );
    ok( exception { $mocked_list->get(1) } );
    is( $mocked_list->get => undef );

    called_ok( sub { $mocked_list->get(0) } );
};

subtest 'Argument matchers' => sub {
    my $mocked_list = mock;
    stub( sub { $mocked_list->get(Int) } )->returns('element');

    my $even_int = declare as Int, where { $_ % 2 == 0 };
    stub( sub { $mocked_list->get($even_int) } )->returns('it is even');

    is( $mocked_list->get(999) => 'element' );
    is( $mocked_list->get(100) => 'it is even' );

    called_ok( sub { $mocked_list->get(Int) }, times => 2 );
};

subtest 'Verifying the number of invocations' => sub {
    my $list = mock;

    $list->add($_) for qw( one two two three three three );

    called_ok( sub { $list->add('one')   } );
    called_ok( sub { $list->add('one')   }, times => 1 );
    called_ok( sub { $list->add('two')   }, times => 2 );
    called_ok( sub { $list->add('three') }, times => 3 );
    called_ok( sub { $list->add('never') }, times => 0 );

    called_ok( sub { $list->add('three') }, at_least => 1 );
    called_ok( sub { $list->add('two')   }, at_most => 2 );
};
