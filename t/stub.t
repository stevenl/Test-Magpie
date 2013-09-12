#!/usr/bin/perl -T
use strict;
use warnings;

use Test::More tests => 21;
use Test::Fatal;

BEGIN { use_ok 'Test::Mocha' }

use Exception::Tiny;
use Test::Mocha::Util qw( get_attribute_value );
use Types::Standard   qw( Any ArrayRef HashRef Int slurpy );

# setup
my $mock  = mock;
my $stubs = get_attribute_value($mock, 'stubs');

# stub() argument checks
like exception { stub() },
    qr/^stub\(\) must be given a mock object/,
    'stub() with no argument throws exception';

like exception { stub('string') },
    qr/^stub\(\) must be given a mock object/,
    'stub() with non-mock argument throws exception';

subtest 'create a method stub that returns a scalar' => sub {
    stub($mock)->foo->returns(4);

    is $stubs->{foo}[0]->as_string, 'foo()';
    is $mock->foo, 4,               'and stub returns the scalar';
    is_deeply [ $mock->foo ], [4],  'or the single-element in a list';
};

subtest 'create a method stub that returns an array' => sub {
    stub($mock)->foo->returns(1, 2, 3);

    is $stubs->{foo}[0]->as_string,      'foo()';
    is_deeply [ $mock->foo ], [1, 2, 3], 'and stub returns the array';
    is $mock->foo, 3,                    'or the array size in scalar context';
};

subtest 'create a method stub that dies' => sub {
    stub($mock)->foo->dies( 'error, ', 'stopped' );

    is $stubs->{foo}[0]->as_string, 'foo()';

    my $exception = exception { $mock->foo };
    like $exception, qr/^error, stopped at /, 'and stub does die';
    like $exception, qr/stub\.t/, 'and error traces back to this script';
};

subtest 'create a method stub that throws exception' => sub {
    stub($mock)->foo->dies(
        Exception::Tiny->new(
            message => 'my exception',
            file => __FILE__,
            line => __LINE__,
        ),
        qw( remaining args are ignored ),
    );
    like exception { $mock->foo },
        qr/^my exception/, 'and the exception is thrown';
};

{
    package NonThrowable;
    use overload '""' => \&message;
    sub new { bless [], $_[0] }
    sub message {'died'}
}
subtest 'create stub dies with a non-exception object' => sub {
    stub($mock)->foo->dies( NonThrowable->new );
    like exception { $mock->foo }, qr/^died/, 'and stub does die';
};

subtest 'create a method stub with no specified response' => sub {
    stub($mock)->foo;
    is $mock->foo, undef, 'and stub returns undef';
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

subtest 'stub with callback' => sub {
    my $list = mock;

    my @returns = qw( first second );

    stub($list)->get(Int)->executes(sub {
        my ($list, $i) = @_;
        die "index out of bounds" if $i < 0;
        return $returns[$i];
    });

    is $list->get(0), 'first', 'returns value';
    is $list->get(1), 'second';
    is $list->get(2),  undef, 'no return value specified';

    like exception { $list->get(-1) }, qr/^index out of bounds/,
        'exception is thrown';

    my $e = exception { stub($list)->get(Int)->executes('not a coderef') };
    like $e, qr/^executes\(\) must be given a coderef/,
        'executes() with a non-coderef argument';
    like $e, qr/stub\.t/, ' and message traces back to this script';
};

stub($mock)->set(Any)->returns('any');
is $mock->set(1), 'any', 'stub() accepts type constraints';

# ----------------------
# stub() with slurpy type constraint

my $stub = stub($mock)->set( slurpy ArrayRef );
is $stub, 'set({ slurpy: ArrayRef })', 'stub() accepts slurpy ArrayRef';
$stub = stub($mock)->set( slurpy HashRef );
is $stub, 'set({ slurpy: HashRef })', 'stub() accepts slurpy HashRef';

my $e = exception { stub($mock)->set( slurpy(ArrayRef), 1 ) };
like $e, qr/^No arguments allowed after a slurpy type constraint/,
    'Disallow arguments after a slurpy type constraint for stub()';
like $e, qr/stub\.t/, ' and message traces back to this script';

$e = exception { stub($mock)->set(slurpy Any) };
like $e, qr/^Slurpy argument must be a type of ArrayRef or HashRef/,
    'Invalid Slurpy argument for stub()';
like $e, qr/stub\.t/, ' and message traces back to this script';

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

stub($mock)->DESTROY;
ok !defined $stubs->{DESTROY}, 'DESTROY() is not AUTOLOADed';
