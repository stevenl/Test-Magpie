#!/usr/bin/perl -T
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Types::Standard qw( Any );

BEGIN { use_ok 'Test::Mocha', qw( mock inspect ) }

my $mock = mock;
$mock->foo;
$mock->foo(123, bar => 456);

my $inspect;

subtest 'inspect()' => sub {
    $inspect = inspect($mock);
    isa_ok $inspect, 'Test::Mocha::Inspect';

    like exception { inspect },
        qr/^inspect\(\) must be given a mock object/,
        'no arg';
    like exception { inspect('string') },
        qr/^inspect\(\) must be given a mock object/,
        'invalid arg';
};

subtest 'get invocation' => sub {
    my $invocation1 = $inspect->foo;
    isa_ok $invocation1, 'Test::Mocha::MethodCall';
    is $invocation1->name, 'foo';
    is_deeply [$invocation1->args], [];
};

subtest 'get invocation with argument matchers' => sub {
    my $invocation2 = $inspect->foo(map {Any} 1..3 );
    isa_ok $invocation2, 'Test::Mocha::MethodCall';
    is $invocation2->name, 'foo';
    is_deeply [$invocation2->args], [123, 'bar', 456];
};

done_testing(4);
