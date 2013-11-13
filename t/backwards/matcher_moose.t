#!/usr/bin/perl -T

use Test::Requires qw(
    Moose::Util::TypeConstraints
    MooseX::Types::Moose
    MooseX::Types::Structured
);

use Moose::Util::TypeConstraints;
use MooseX::Types::Moose      qw( Any ArrayRef Int Str );
use MooseX::Types::Structured qw( Tuple );

use strict;
use warnings;
no warnings 'deprecated';

use Test::More tests => 8;
use Test::Builder::Tester;

BEGIN { use_ok 'Test::Mocha' }

my $mock = mock;

$mock->set( ['foo'] );
$mock->set( ['foo', 'bar'] );
$mock->set( +1, 'not an int' );
$mock->set( -1, 'negative' );

is(
    $mock->foo(1, mock), undef,
    'mock as method argument not isa(Moose::Meta::typeConstraint)'
);

stub($mock)->set(Any)->returns('any');
is( $mock->set(1), 'any', 'stub() accepts type constraints' );

test_out('ok 1 - set(Int) was called 1 time(s)');
verify($mock)->set(Int);
test_test('verify() accepts type constraints');

my $positive_int = subtype 'PositiveInt', as Int, where { $_ > 0 };
test_out('ok 1 - set(PositiveInt, Str) was called 1 time(s)');
verify($mock)->set($positive_int, Str);
test_test('self-defined type constraint works');


test_out('ok 1 - set(ArrayRef[Str]) was called 2 time(s)');
verify($mock, times => 2)->set( ArrayRef[Str] );
test_test('parameterized type works');

test_out('ok 1 - set(ArrayRef|Int) was called 3 time(s)');
verify($mock, times => 3)->set( ArrayRef | Int );
test_test('type union works');


test_out('ok 1 - set(MooseX::Types::Structured::Tuple[Str,Str]) was called 1 time(s)');
verify($mock)->set( Tuple[Str,Str] );
test_test('structured type works');
