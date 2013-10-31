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

    verify($mocked_list)->add('one');
    verify($mocked_list)->clear;
};

subtest 'How about some stubbing?' => sub {
    my $mocked_list = mock;

    stub($mocked_list)->get(0)->returns('first');
    stub($mocked_list)->get(1)->throws('Kaboom!');

    is($mocked_list->get(0) => 'first');
    ok(exception { $mocked_list->get(1) });
    is($mocked_list->get => undef);

    verify($mocked_list)->get(0);
};

subtest 'Argument matchers' => sub {
    my $mocked_list = mock;
    stub($mocked_list)->get(Int)->returns('element');

    my $even_int = declare as Int, where { $_ % 2 == 0 };
    stub($mocked_list)->get($even_int)->returns('it is even');

    is($mocked_list->get(999) => 'element');
    is($mocked_list->get(100) => 'it is even');

    verify($mocked_list, times => 2)->get(Int);
};

subtest 'Verifying the number of invocations' => sub {
    my $list = mock;

    $list->add($_) for qw( one two two three three three );

    verify($list)->add('one');
    verify($list, times => 1)->add('one');
    verify($list, times => 2)->add('two');
    verify($list, times => 3)->add('three');
    verify($list, times => 0)->add('never');

    verify($list, at_least => 1)->add('three');
    verify($list, at_most => 2)->add('two');
};
