#!/usr/bin/perl -T
use strict;
use warnings;

use Test::More tests => 10;
use Test::Fatal;

BEGIN { use_ok 'Test::Mocha' }

use Exception::Tiny;
use Test::Mocha::Util qw( get_attribute_value );
#use Test::Mocha::Matcher qw( anything );

# setup
my $mock  = mock;
my $calls = get_attribute_value($mock, 'calls');
my $stubs = get_attribute_value($mock, 'stubs');

subtest 'create a method stub that returns a scalar' => sub {
    stub($mock)->foo->returns(1);
    is $stubs->{foo}[0]->as_string, 'foo()';
    is $mock->foo, 1, 'and stub returns the scalar';
};

subtest 'create a method stub that returns an array' => sub {
    stub($mock)->foo->returns(1, 2, 3);
    is $stubs->{foo}[0]->as_string, 'foo()';

    is_deeply [ $mock->foo ], [ 1, 2, 3 ], 'and stub returns the array';
    is $mock->foo, 3,                      'or the array size in scalar context';
};

subtest 'create a method stub that dies' => sub {
    stub($mock)->foo->dies('died');
    is $stubs->{foo}[0]->as_string, 'foo()',

    my $exception = exception { $mock->foo };
    like $exception, qr/^died at /, 'and stub does die';
    like $exception, qr/stub\.t/,   'and error traces back to this script';
};

subtest 'create a method stub that throws exception' => sub {
    stub($mock)->foo->dies(
        Exception::Tiny->new(
            message => 'my exception',
            file => __FILE__,
            line => __LINE__,
        )
    );
    like exception { $mock->foo }, qr/^my exception/,
        'and the exception is thrown';
};

subtest 'stub applies to the exact name and arguments specified' => sub {
    my $list = mock;
    stub($list)->get(0)->returns('first');
    stub($list)->get(1)->returns('second');

    is $list->get(0),   'first';
    is $list->get(1),   'second';
    is $list->get(2),   undef;
    is $list->get(),    undef;
    is $list->get(1,2), undef;
    is $list->set(0),   undef;
};

subtest 'stub response persists until it is overridden' => sub {
    my $warehouse = mock;
    my $item = mock;
    stub($warehouse)->has_inventory($item, 10)->returns(1);
    ok( $warehouse->has_inventory($item, 10) ) for 1 .. 5;

    stub($warehouse)->has_inventory($item, 10)->returns(0);
    ok( !$warehouse->has_inventory($item, 10) ) for 1 .. 5;
};

subtest 'stub can chain responses' => sub {
    my $iterator = mock;
    stub($iterator)->next
        ->returns(1)->returns(2)->returns(3)->dies('exhuasted');

    ok $iterator->next == 1;
    ok $iterator->next == 2;
    ok $iterator->next == 3;
    ok exception { $iterator->next };
};

# stub() argument checks
like exception { stub() },
    qr/^stub\(\) must be given a mock object/,
    'stub() with no argument throws exception';

like exception { stub('string') },
    qr/^stub\(\) must be given a mock object/,
    'stub() with non-mock argument throws exception';

# {
#     package NonThrowable;
#     use overload '""' => \&message;
#     sub new { bless [], $_[0] }
#     sub message {'died'}
# }
#
# subtest 'dies' => sub {
#     my $dog = mock;
#     my $stub = stub($dog)->meow;
#     is $stub
#         ->dies( NonThrowable->new )
#
#     like exception { $dog->meow }, qr/^died/, 'died (blessed, cannot throw)';
# };
#
# subtest 'argument matching' => sub {
#     my $list = mock;
#     stub($list)->get(0)->returns('first');
#     stub($list)->get(1)->returns('second');
#     stub($list)->get()->dies('no index given');
#
#     ok ! $list->set(0, '1st'), 'no such method';
#     ok ! $list->get(0, 1),     'extra args';
#
#     is $list->get(0), 'first', 'exact match';
#     is $list->get(1), 'second';
#     like exception { $list->get() }, qr/^no index given/, 'no args';
#
#     stub($list)->get(anything)->dies('index out of bounds');
#     like exception { $list->get(-1) }, qr/index out of bounds/,
#         'argument matcher';
# };
