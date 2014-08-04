#!/usr/bin/perl -T

use strict;
use warnings;
no warnings 'deprecated';

use Test::More tests => 23;
use Test::Fatal;

BEGIN { use_ok 'Test::Mocha' }

use Test::Mocha::Util qw( getattr );
use Types::Standard qw( Any Int slurpy );

# setup
my $mock = mock;
my $stubs = getattr( $mock, 'stubs' );

# stub() argument checks
like(
    exception { stub() },
    qr/^stub\(\) must be given a coderef/,
    'stub() with no argument throws exception'
);

like(
    exception { stub('string') },
    qr/^stub\(\) must be given a coderef/,
    'stub() with non-mock argument throws exception'
);

subtest 'create a method stub that returns a scalar' => sub {
    stub($mock)->foo(1)->returns(4);

    is( $stubs->{foo}[0]->stringify, 'foo(1)' );
    is( $mock->foo(1), 4, '... and stub returns the scalar' );
    is_deeply( [ $mock->foo(1) ], [4], '...or the single-element in a list' );
};

subtest 'create a method stub that returns an array' => sub {
    stub($mock)->foo(2)->returns( 1, 2, 3 );

    is( $stubs->{foo}[0]->stringify, 'foo(2)' );
    is_deeply(
        [ $mock->foo(2) ],
        [ 1, 2, 3 ],
        '... and stub returns the array'
    );
    is( $mock->foo(2), 3, '... or the array size in scalar context' );
};

subtest 'create a method stub that returns nothing' => sub {
    stub($mock)->foo(3)->returns;

    is( $stubs->{foo}[0]->stringify, 'foo(3)' );
    is( $mock->foo(3), undef, '... and stub returns undef' );
    is_deeply( [ $mock->foo(3) ], [], '... or an empty list' );
};

subtest 'create a method stub that throws' => sub {
    stub($mock)->foo(4)->throws( 'error, ', 'stopped' );

    is( $stubs->{foo}[0]->stringify, 'foo(4)' );

    my $exception = exception { $mock->foo(4) };
    like( $exception, qr/^error, stopped at /, '... and stub does die' );
    like( $exception, qr/stub\.t/, '... and error traces back to this script' );
};

subtest 'create a method stub that throws with no arguments' => sub {
    stub($mock)->foo('4a')->throws;

    is( $stubs->{foo}[0]->stringify, 'foo("4a")' );

    my $exception = exception { $mock->foo('4a') };
    like( $exception, qr/^ at /,   '... and stub does die' );
    like( $exception, qr/stub\.t/, '... and error traces back to this script' );
};

{

    package My::Throwable;

    sub new {
        my ( $class, $message ) = @_;
        return bless { message => $message }, $class;
    }
    sub throw { die $_[0]->{message} }
}
subtest 'create a method stub that throws exception' => sub {
    stub($mock)->foo(5)->throws(
        My::Throwable->new('my exception'),
        qw( remaining args are ignored ),
    );
    like(
        exception { $mock->foo(5) },
        qr/^my exception/,
        'and the exception is thrown'
    );
};

{

    package My::NonThrowable;
    use overload '""' => \&message;
    sub new { bless [], $_[0] }
    sub message { 'died' }
}
subtest 'create stub throws with a non-exception object' => sub {
    stub($mock)->foo(6)->throws( My::NonThrowable->new );
    like( exception { $mock->foo(6) }, qr/^died/, '... and stub does die' );
};

subtest 'create a method stub with no specified response' => sub {
    stub($mock)->foo(7);
    is( $stubs->{foo}[0]->stringify, 'foo(7)' );
    is( $mock->foo(7), undef, '... and stub returns undef' );
    is_deeply( [ $mock->foo(7) ], [], '... or an empty list' );
};

subtest 'stub applies to the exact name and arguments specified' => sub {
    my $list = mock;
    stub($list)->get(0)->returns('first');
    stub($list)->get(1)->returns('second');

    is( $list->get(0), 'first' );
    is( $list->get(1), 'second' );
    is( $list->get(2), undef );
    is( $list->get(),  undef );
    is( $list->get( 1, 2 ), undef );
    is( $list->set(0), undef );
};

subtest 'stub response persists until it is overridden' => sub {
    my $warehouse = mock;
    my $item      = mock;
    stub($warehouse)->has_inventory( $item, 10 )->returns(1);
    ok( $warehouse->has_inventory( $item, 10 ) ) for 1 .. 5;

    stub($warehouse)->has_inventory( $item, 10 )->returns(0);
    ok( !$warehouse->has_inventory( $item, 10 ) ) for 1 .. 5;
};

subtest 'stub can chain responses' => sub {
    my $iterator = mock;
    stub($iterator)->next->returns(1)->returns(2)->returns(3)
      ->throws('exhausted');

    ok( $iterator->next == 1 );
    ok( $iterator->next == 2 );
    ok( $iterator->next == 3 );
    like( exception { $iterator->next }, qr/exhausted/ );
};

subtest 'stub with callback' => sub {
    my $list = mock;

    my @returns = qw( first second );

    stub($list)->get(Int)->executes(
        sub {
            my ( $list, $i ) = @_;
            die "index out of bounds" if $i < 0;
            return $returns[$i];
        }
    );

    is( $list->get(0), 'first', 'returns value' );
    is( $list->get(1), 'second' );
    is( $list->get(2), undef,   'no return value specified' );

    like(
        exception { $list->get(-1) },
        qr/^index out of bounds/,
        'exception is thrown'
    );

    my $e = exception { stub($list)->get(Int)->executes('not a coderef') };
    like(
        $e,
        qr/^executes\(\) must be given a coderef/,
        'executes() with a non-coderef argument'
    );
    like( $e, qr/stub\.t/, '... and message traces back to this script' );
};

stub($mock)->set(Any)->returns('any');
is( $mock->set(1), 'any', 'stub() accepts type constraints' );

# ----------------------
# stub() with slurpy type constraint

my $stub;
$stub = stub($mock)->set(SlurpyArray);
is( $stub, 'set({ slurpy: ArrayRef })', 'stub() accepts slurpy ArrayRef' );
$stub = stub($mock)->set(SlurpyHash);
is( $stub, 'set({ slurpy: HashRef })', 'stub() accepts slurpy HashRef' );

my $e = exception { stub($mock)->set( SlurpyArray, 1 ) };
like(
    $e,
    qr/^No arguments allowed after a slurpy type constraint/,
    'Disallow arguments after a slurpy type constraint for stub()'
);
like( $e, qr/stub\.t/, '... and message traces back to this script' );

$e = exception { stub($mock)->set( slurpy Any ) };
like(
    $e,
    qr/^Slurpy argument must be a type of ArrayRef or HashRef/,
    'Invalid Slurpy argument for stub()'
);
like( $e, qr/stub\.t/, '... and message traces back to this script' );

stub($mock)->DESTROY;
ok( !defined $stubs->{DESTROY}, 'DESTROY() is not AUTOLOADed' );
