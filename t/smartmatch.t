#!/usr/bin/perl -T
use strict;
use warnings;

# smartmatch dependency
use 5.010001;

# These tests are to make sure that no unexpected argument matches occur
# because we are using smartmatching

use Test::More tests => 11;

BEGIN { use_ok 'Test::Mocha' }

use constant MethodCall => 'Test::Mocha::MethodCall';

subtest 'X ~~ Array' => sub {
    my $mock = mock;

    $mock->array( [1, 2, 3] );
    verify($mock, 'Array ~~ Array')->array( [1, 2, 3] );
    verify($mock, times => 0, 'Array.size != Array.size')->array( [1, 2] );

    $mock->hash( {a => 1} );
    verify($mock, times => 0, 'Hash ~~ Array')->hash( [qw/a b c/] );

    $mock->regexp( qr/^hell/ );
    verify($mock, times => 0, 'Regexp ~~ Array')->regexp( [qw/hello/] );

    $mock->undef(undef);
    verify($mock, times => 0, 'Undef ~~ Array')->undef( [undef, 'anything'] );

    $mock->any(1);
    verify($mock, times => 0, 'Any ~~ Array')->any( [1,2,3] );
};

subtest 'X ~~ Array (nested)' => sub {
    my $mock = mock;

    $mock->nested_array( [1, 2, [3, 4]] );
    verify($mock, 'Array[Array] ~~ Array[Array]')
        ->nested_array( [1, 2, [3, 4]] );

    $mock->nested_hash( [1, 2, {3 => 4}] );
    verify($mock, 'Array[Hash] ~~ Array[Hash]')
        ->nested_hash( [1, 2, {3 => 4}] );

    $mock->array( [1, 2, 3] );
    verify($mock, times => 0, 'Array ~~ Array[Array]')
        ->array( [1, 2, [3, 4]] );

    verify($mock, times => 0, 'Array ~~ Array[Hash]')
        ->array( [1, 2, {3 => 4}] );
};

subtest 'X ~~ Hash' => sub {
    my $mock = mock;

    $mock->hash( {a => 1, b => 2, c => 3} );
    verify($mock, 'Hash ~~ Hash')->hash( {c => 3, b => 2, a => 1} );

    verify($mock, times => 0, 'Hash ~~ Hash - different keys')
        ->hash( {a => 3, b => 2, d => 1} );

    verify($mock, times => 0, 'Hash ~~ Hash - same keys, different values')
        ->hash( {a => 3, b => 2, c => 1} );

    $mock->array( [qw/a b c/] );
    verify($mock, times => 0, 'Array ~~ Hash')->array( {a => 1} );

    $mock->regexp(qr/^hell/);
    verify($mock, times => 0, 'Regexp ~~ Hash')->regexp( {hello => 1} );

    $mock->any('a');
    verify($mock, times => 0, 'Any ~~ Hash')->any( {a => 1, b => 2} );
};

subtest 'X ~~ Code' => sub {
    my $mock = mock;

    $mock->array( [1, 2, 3] );
    verify($mock, times => 0, 'Array ~~ Code')->array( sub {1} );

    # empty arrays always match
    $mock->array( [] );
    verify($mock, times => 0, 'Array(empty) ~~ Code')->array( sub {0} );

    $mock->hash( {a => 1, b => 2} );
    verify($mock, times => 0, 'Hash ~~ Code')->hash( sub {1} );

    # empty hashes always match
    $mock->hash( {} );
    verify($mock, times => 0, 'Hash(empty) ~~ Code')->hash( sub {0} );

    $mock->code('anything');
    verify($mock, times => 0, 'Any ~~ Code')->code( sub {1} );

    $mock->code( sub {0} );
    verify($mock, times => 0, 'Code ~~ Code')->code( sub {1} );

    # same coderef should match
    $mock = mock;
    my $sub = sub {0};
    $mock->code($sub);
    verify($mock, 'Code == Code')->code($sub);
};

subtest 'X ~~ Regexp' => sub {
    my $mock = mock;

    $mock->array( [qw/hello bye/] );
    verify($mock, times => 0, 'Array ~~ Regexp')->array( qr/^hell/ );

    $mock->hash( {hello => 1} );
    verify($mock, times => 0, 'Array ~~ Regexp')->hash( qr/^hell/ );

    $mock->any('hello');
    verify($mock, times => 0, 'Any ~~ Regexp')->any( qr/^hell/ );
};

subtest 'X ~~ Undef' => sub {
    my $mock = mock;

    $mock->undef(undef);
    verify($mock, 'Undef ~~ Undef')->undef(undef);

    $mock->any(1);
    verify($mock, times => 0, 'Any ~~ Undef')->any(undef);

    verify($mock, times => 0, 'Undef ~~ Any')->undef(1);
};

{
    package My::Object;
    sub new {
        my ($class, %args) = @_;
        return bless \%args, $class;
    }

    package My::Overloaded;
    use overload '~~' => 'match', 'bool' => sub {1};
    sub new {
        my ($class, %args) = @_;
        return bless \%args, $class;
    }
    sub match {
        no warnings; # suppress smartmatch warnings
        my ($self, $other) = @_;
        return $self->{value} ~~ $other;
    }
}

subtest 'X ~~ Object (overloaded)' => sub {
    my $mock = mock;
    my $overloaded = My::Overloaded->new(value => 5);

    $mock->any( [1,3,5] );
    verify($mock, times => 0, 'Any ~~ Object')->any($overloaded);

    $mock->object($overloaded);
    verify($mock, 'Object == Object')->object($overloaded);
};

subtest 'X ~~ Object (non-overloaded)' => sub {
    my $mock = mock;
    my $obj = My::Object->new(value => 5);

    $mock->object($obj);
    verify($mock, 'Object == Object')->object($obj);

    $mock->mock($mock);
    verify($mock, 'Mock == Mock')->mock($mock);

    # This scenario won't invoke the overload method because smartmatching
    # rules take precedence over overloading. The comparison is meant to be
    # `$obj eq 'My::Object` but this doesn't seem to be happening
    $mock->object($obj);
    verify($mock, times => 0, 'Object ~~ Any')->object('My::Object');

};

subtest 'X ~~ Num' => sub {
    my $mock = mock;

    $mock->int(5);
    verify($mock, 'Int == Int')->int(5);
    verify($mock, 'Int == Num')->int(5.0);

    $mock->str('42x');
    verify($mock, times => 0, 'Str ~~ Num (42x == 42)')->str(42);
};

subtest 'X ~~ Str' => sub {
    my $mock = mock;

    $mock->str('foo');
    verify($mock, 'Str eq Str')->str('foo');
    verify($mock, times => 0, 'Str ne Str')->str('Foo');
    verify($mock, times => 0, 'Str ne Str')->str('bar');

    $mock->int(5);
    verify($mock, 'Int ~~ Num-like')->int("5.0");
    verify($mock, times => 0, 'Int !~ Num-like (5 eq 5x)')->int("5x");

    TODO: {
        local $TODO = "string still looks_like_number in spite of whitespace";
        verify($mock, times => 0, 'Int !~ Num-like (5 eq 5\\n)')->int("5\n");
    }
};
