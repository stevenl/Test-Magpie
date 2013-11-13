#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 29;
use Test::Fatal;

BEGIN { use_ok 'Test::Mocha' }

use Test::Mocha::Util qw( getattr );
use Types::Standard   qw( Any Int slurpy );

# setup
my $file  = __FILE__;
my $mock  = mock;
my $stubs = getattr( $mock, 'stubs' );
my $e;

# stub() argument checks
like(
    $e = exception { stub() },
    qr/^stub\(\) must be given a coderef/,
    'stub() expects an argument'
);
like(
    $e = exception { stub('string') },
    qr/^stub\(\) must be given a coderef/,
    '... and it must be a coderef'
);
like(
    $e, qr/at \Q$file\E/,
    '... and error traces back to this script'
);

like(
    $e = exception { stub( sub {} ) },
    qr/Coderef must have a single method invocation on a mock object/,
    'stub() coderef must contain a method call specification'
);
like(
    $e, qr/at \Q$file\E/,
    '... and error traces back to this script'
);

like(
    $e = exception { stub( sub { $mock->first; $mock->second } ) },
    qr/Coderef must have a single method invocation on a mock object/,
    'stub() coderef may not contain multiple method call specifications'
);
like(
    $e, qr/at \Q$file\E/,
    '... and error traces back to this script'
);

subtest 'create stub that returns a scalar' => sub {
    stub( sub { $mock->foo(1) } )->returns(4);

    is( $stubs->{foo}[0]->stringify,   'foo(1)' );
    is( $mock->foo(1), 4,              '... and stub returns the scalar' );
    is_deeply( [ $mock->foo(1) ], [4], '...or the single-element in a list' );
};

subtest 'create stub that returns an array' => sub {
    stub( sub { $mock->foo(2) } )->returns(1, 2, 3);

    is( $stubs->{foo}[0]->stringify,         'foo(2)' );
    is_deeply( [ $mock->foo(2) ], [1, 2, 3], '... and stub returns the array' );
    is( $mock->foo(2), 3, '... or the array size in scalar context' );
};

subtest 'create stub that returns nothing' => sub {
    stub( sub { $mock->foo(3) } )->returns;

    is( $stubs->{foo}[0]->stringify,   'foo(3)' );
    is( $mock->foo(3), undef,          '... and stub returns undef' );
    is_deeply( [ $mock->foo(3) ], [ ], '... or an empty list' );
};

subtest 'create stub that throws' => sub {
    stub( sub { $mock->foo(4) } )->throws( 'error, ', 'stopped' );

    is( $stubs->{foo}[0]->stringify, 'foo(4)' );

    $e = exception { $mock->foo(4) };
    like( $e, qr/^error, stopped at /, '... and stub does die' );
    like( $e, qr/\Q$file\E/, '... and error traces back to this script' );
};

subtest 'create stub that throws with no arguments' => sub {
    stub( sub { $mock->foo('4a') } )->throws();

    is( $stubs->{foo}[0]->stringify, 'foo("4a")' );

    my $e = exception { $mock->foo('4a') };
    like( $e, qr/^ at /,   '... and stub does die' );
};

{
    package My::Throwable;
    sub new {
        my ($class, $message) = @_;
        return bless { message => $message }, $class;
    }
    sub throw { die $_[0]->{message} }
}
subtest 'create stub that throws with an exception object' => sub {
    stub( sub { $mock->foo(5) } )->throws(
        My::Throwable->new('my exception'),
        qw( remaining args are ignored ),
    );
    like(
        $e = exception { $mock->foo(5) }, qr/^my exception/,
        '... and the exception is thrown'
    );
    like( $e, qr/\Q$file\E/, '... and error traces back to this script' );
};

{
    package My::NonThrowable;
    use overload '""' => \&message;
    sub new { bless [], $_[0] }
    sub message {'died'}
}
subtest 'create stub throws with a non-exception object' => sub {
    stub( sub { $mock->foo(6) } )->throws( My::NonThrowable->new );
    like(
        $e = exception { $mock->foo(6) }, qr/^died/,
        '... and stub does throw'
    );
    TODO: {
        # Carp BUGS section:
        # The Carp routines don't handle exception objects currently.
        # If called with a first argument that is a reference,
        # they simply call die() or warn(), as appropriate.
        local $TODO = 'Carp does not handle objects';
        like(
            $e, qr/at \Q$file\E/,
            '... and error traces back to this script'
        );
    }
};

subtest 'create stub with no specified response' => sub {
    stub( sub { $mock->foo(7) } );
    is( $stubs->{foo}[0]->stringify,   'foo(7)' );
    is( $mock->foo(7), undef,          '... and stub returns undef' );
    is_deeply( [ $mock->foo(7) ], [ ], '... or an empty list' );
};

subtest 'stub applies to the exact name and arguments specified' => sub {
    my $list = mock;
    stub( sub { $list->get(0) } )->returns('first');
    stub( sub { $list->get(1) } )->returns('second');

    is( $list->get(0),   'first' );
    is( $list->get(1),   'second' );
    is( $list->get(2),   undef );
    is( $list->get(),    undef );
    is( $list->get(1,2), undef );
    is( $list->set(0),   undef );
};

subtest 'stub response persists until it is overridden' => sub {
    my $warehouse = mock;
    my $item = mock;
    stub( sub { $warehouse->has_inventory($item, 10) } )->returns(1);
    ok( $warehouse->has_inventory($item, 10) ) for 1 .. 5;

    stub( sub { $warehouse->has_inventory($item, 10) } )->returns(0);
    ok( !$warehouse->has_inventory($item, 10) ) for 1 .. 5;
};

subtest 'stub can chain responses' => sub {
    my $iterator = mock;
    stub( sub { $iterator->next } )
        ->returns(1)
        ->returns(2)
        ->returns(3)
        ->throws('exhausted');

    ok( $iterator->next == 1 );
    ok( $iterator->next == 2 );
    ok( $iterator->next == 3 );
    like( exception { $iterator->next }, qr/exhausted/ );
};

subtest 'stub with callback' => sub {
    my $list = mock;

    my @returns = qw( first second );

    stub( sub { $list->get(Int) } )->executes(sub {
        my ($list, $i) = @_;
        die "index out of bounds" if $i < 0;
        return $returns[$i];
    });

    is( $list->get(0), 'first', 'returns value' );
    is( $list->get(1), 'second' );
    is( $list->get(2),  undef, 'no return value specified' );

    like(
        exception { $list->get(-1) },
        qr/^index out of bounds/, 'exception is thrown'
    );

    my $e = exception {
        stub( sub { $list->get(Int) } )->executes('not a coderef')
    };
    like(
        $e, qr/^executes\(\) must be given a coderef/,
        'executes() expects a coderef argument'
    );
    like( $e, qr/at \Q$file\E/, '... and error traces back to this script' );
};

subtest 'add a stub over an existing one' => sub {
    my $iterator = mock;
    stub( sub { $iterator->next(SlurpyArray) } )
        ->returns(1)
        ->returns(2);

    stub( sub { $iterator->next(Any) } )->throws('invalid');

    like( exception { $iterator->next(1) }, qr/^invalid/ );
    is( $iterator->next, 1 );
};

subtest 'add a stub over an existing one that throws' => sub {
    my $iterator = mock;
    stub( sub { $iterator->next(SlurpyArray) } )
        ->throws('exception')
        ->returns(2);

    stub( sub { $iterator->next(Any) } )->throws('invalid');

    like( exception { $iterator->next(1) }, qr/^invalid/ );
    like( exception { $iterator->next },    qr/^exception/ );
};

stub( sub { $mock->set(Int) } )->returns('any');
is( $mock->set(1), 'any', 'stub() accepts type constraints' );

# ----------------------
# stub() with slurpy type constraint

my $stub = stub( sub { $mock->set(SlurpyArray) } );
is( $stub, 'set({ slurpy: ArrayRef })', 'stub() accepts slurpy ArrayRef' );
$stub = stub( sub { $mock->set(SlurpyHash) } );
is( $stub, 'set({ slurpy: HashRef })', 'stub() accepts slurpy HashRef' );

like(
    $e = exception { stub( sub { $mock->set(SlurpyArray, 1) } ) },
    qr/^No arguments allowed after a slurpy type constraint/,
    'Arguments after a slurpy type constraint are not allowed'
);
like( $e, qr/at \Q$file\E/, '... and error traces back to this script' );

like(
    $e = exception { stub( sub { $mock->set(slurpy Any) } ) },
    qr/^Slurpy argument must be a type of ArrayRef or HashRef/,
    'Slurpy argument must be an arrayref of hashref'
);
like( $e, qr/at \Q$file\E/, '... and error traces back to this script' );
