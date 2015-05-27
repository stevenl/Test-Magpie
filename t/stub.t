#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 23;
use Test::Fatal;
use Types::Standard qw( Any Int slurpy );

BEGIN { use_ok 'Test::Mocha' }

# setup
my $FILE = __FILE__;
my $mock = mock;

# stub() argument checks
subtest 'stub() responses must be coderefs' => sub {
    like(
        my $e = exception {
            stub { $mock->any } 1, 2, 3;
        },
        qr/^stub\(\) responses should be supplied using returns\(\), throws\(\) or executes\(\)/,
        'error is thrown'
    );
    like( $e, qr/at \Q$FILE\E/, '... and error traces back to this script' );
};

subtest 'stub() coderef must contain a method call specification' => sub {
    like(
        my $e = exception { stub {} },
        qr/Coderef must have a method invoked on a mock object/,
        'error is thrown'
    );
    like( $e, qr/at \Q$FILE\E/, '... and error traces back to this script' );
};

subtest 'stub() coderef may not contain multiple method call specifications' =>
  sub {
    like(
        my $e = exception {
            stub { $mock->first; $mock->second };
        },
        qr/Coderef must not have multiple methods invoked on a mock object/,
        'error is thrown'
    );
    like( $e, qr/at \Q$FILE\E/, '... and error traces back to this script' );
  };

subtest 'create stub that returns a scalar' => sub {
    stub { $mock->foo(1) } returns 4;

    is( $mock->__stubs->{foo}[0]->stringify, 'foo(1)' );
    is( $mock->foo(1), 4, '... and stub returns the scalar' );
    is_deeply( [ $mock->foo(1) ], [4], '...or the single-element in a list' );
};

subtest 'create stub that returns an array' => sub {
    stub { $mock->foo(2) } returns 1, 2, 3;

    is( $mock->__stubs->{foo}[0]->stringify, 'foo(2)' );
    is_deeply(
        [ $mock->foo(2) ],
        [ 1, 2, 3 ],
        '... and stub returns the array'
    );
    is( $mock->foo(2), 3, '... or the array size in scalar context' );
};

subtest 'create stub that returns nothing' => sub {
    stub { $mock->foo(3) } returns;

    is( $mock->__stubs->{foo}[0]->stringify, 'foo(3)' );
    is( $mock->foo(3), undef, '... and stub returns undef' );
    is_deeply( [ $mock->foo(3) ], [], '... or an empty list' );
};

subtest 'create stub that throws' => sub {
    stub { $mock->foo(4) } throws 'error, ', 'stopped';

    is( $mock->__stubs->{foo}[0]->stringify, 'foo(4)' );

    my $e = exception { $mock->foo(4) };
    like( $e, qr/^error, stopped at /, '... and stub does die' );
    like( $e, qr/\Q$FILE\E/, '... and error traces back to this script' );
};

subtest 'create stub that throws with no arguments' => sub {
    stub { $mock->foo('4a') } throws;

    is( $mock->__stubs->{foo}[0]->stringify, 'foo("4a")' );

    my $e = exception { $mock->foo('4a') };
    like( $e, qr/^ at /, '... and stub does die' );
};

{

    package My::Throwable;

    sub new {
        my ( $class, $message ) = @_;
        return bless { message => $message }, $class;
    }
    sub throw { die $_[0]->{message} }
}
subtest 'create stub that throws with an exception object' => sub {
    stub { $mock->foo(5) } throws(
        My::Throwable->new('my exception'),
        qw( remaining args are ignored ),
    );
    like(
        my $e = exception { $mock->foo(5) },
        qr/^my exception/,
        '... and the exception is thrown'
    );
    like( $e, qr/\Q$FILE\E/, '... and error traces back to this script' );
};

{

    package My::NonThrowable;
    use overload '""' => \&message;
    sub new { bless [], $_[0] }
    sub message { 'died' }
}
subtest 'create stub throws with a non-exception object' => sub {
    stub { $mock->foo(6) } throws( My::NonThrowable->new );
    like( my $e = exception { $mock->foo(6) },
        qr/^died/, '... and stub does throw' );
  TODO: {
        # Carp BUGS section:
        # The Carp routines don't handle exception objects currently.
        # If called with a first argument that is a reference,
        # they simply call die() or warn(), as appropriate.
        local $TODO = 'Carp does not handle objects';
        like( $e, qr/at \Q$FILE\E/,
            '... and error traces back to this script' );
    }
};

subtest 'create stub with no specified response' => sub {
    stub { $mock->foo(7) };
    is( $mock->__stubs->{foo}[0]->stringify, 'foo(7)' );
    is( $mock->foo(7), undef, '... and stub returns undef' );
    is_deeply( [ $mock->foo(7) ], [], '... or an empty list' );
};

subtest 'stub applies to the exact name and arguments specified' => sub {
    my $list = mock;
    stub { $list->get(0) } returns 'first';
    stub { $list->get(1) } returns 'second';

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
    stub { $warehouse->has_inventory( $item, 10 ) } returns 1;
    ok( $warehouse->has_inventory( $item, 10 ) ) for 1 .. 5;

    stub { $warehouse->has_inventory( $item, 10 ) } returns 0;
    ok( !$warehouse->has_inventory( $item, 10 ) ) for 1 .. 5;
};

subtest 'stub can chain responses' => sub {
    my $iterator = mock;
    stub { $iterator->next } returns(1), returns(2), returns(3),
      throws('exhausted');

    ok( $iterator->next == 1 );
    ok( $iterator->next == 2 );
    ok( $iterator->next == 3 );
    like( exception { $iterator->next }, qr/exhausted/ );
};

subtest 'stub with callback' => sub {
    my $list    = mock;
    my @returns = qw( first second );

    stub { $list->get(Int) }
    executes {
        my ( $list, $i ) = @_;
        die "index out of bounds" if $i < 0;
        return $returns[$i];
    };

    is( $list->get(0), 'first', 'returns value' );
    is( $list->get(1), 'second' );
    is( $list->get(2), undef,   'no return value specified' );

    like(
        exception { $list->get(-1) },
        qr/^index out of bounds/,
        'exception is thrown'
    );
};

subtest 'add a stub over an existing one' => sub {
    my $iterator = mock;
    stub { $iterator->next(SlurpyArray) } returns(1), returns(2);
    stub { $iterator->next(Any) } throws 'invalid';

    like( exception { $iterator->next(1) }, qr/^invalid/ );
    is( $iterator->next, 1 );
};

subtest 'add a stub over an existing one that throws' => sub {
    my $iterator = mock;
    stub { $iterator->next(SlurpyArray) } throws('exception'), returns(2);
    stub { $iterator->next(Any) } throws 'invalid';

    like( exception { $iterator->next(1) }, qr/^invalid/ );
    like( exception { $iterator->next },    qr/^exception/ );
};

stub { $mock->set(Int) } returns 'any';
is( $mock->set(1), 'any', 'stub() accepts type constraints' );

# ----------------------
# stub() with slurpy type constraint

stub { $mock->set(SlurpyArray) };
is(
    $mock->__stubs->{set}[0],
    'set({ slurpy: ArrayRef })',
    'stub() accepts slurpy ArrayRef'
);

stub { $mock->set(SlurpyHash) };
is(
    $mock->__stubs->{set}[0],
    'set({ slurpy: HashRef })',
    'stub() accepts slurpy HashRef'
);

subtest 'Arguments after a slurpy type constraint are not allowed' => sub {
    like(
        my $e = exception {
            stub { $mock->set( SlurpyArray, 1 ) };
        },
        qr/^No arguments allowed after a slurpy type constraint/,
        'error is thrown'
    );
    like( $e, qr/at \Q$FILE\E/, '... and error traces back to this script' );
};

subtest 'Slurpy argument must be an arrayref of hashref' => sub {
    like(
        my $e = exception {
            stub { $mock->set( slurpy Any ) };
        },
        qr/^Slurpy argument must be a type of ArrayRef or HashRef/,
        'error is thrown'
    );
    like( $e, qr/at \Q$FILE\E/, '... and error traces back to this script' );
};
