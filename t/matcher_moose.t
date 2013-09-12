#!perl -T
use strict;
use warnings;

use Test::More tests => 10;
use Test::Builder::Tester;
use Test::Fatal;
use Test::Requires qw(
    Moose::Util::TypeConstraints
    MooseX::Types::Moose
    MooseX::Types::Structured
);

use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw( Any ArrayRef Int Str );
use MooseX::Types::Structured qw( Tuple );

BEGIN { use_ok 'Test::Mocha' }

my $mock = mock;

$mock->set(['foo']);
$mock->set(['foo', 'bar']);
$mock->set(+1, 'not an int');
$mock->set(-1, 'negative');

my $e = exception { $mock->foo(1, Int) };
like $e, qr/Int/,
    'mock does not accept method calls with type constraint arguments';
like $e, qr/matcher_moose\.t/, ' and message traces back to this script';

is $mock->foo(1, mock), undef,
    'mock as method argument not isa(Moose::Meta::typeConstraint)';

stub($mock)->set(Any)->returns('any');
is $mock->set(1), 'any', 'stub() accepts type constraints';

test_out 'ok 1 - set(Int) was called 1 time(s)';
verify($mock)->set(Int);
test_test 'verify() accepts type constraints';

my $positive_int = subtype 'PositiveInt', as Int, where { $_ > 0 };
test_out 'ok 1 - set(PositiveInt, Str) was called 1 time(s)';
verify($mock)->set($positive_int, Str);
test_test 'self-defined type constraint works';


test_out 'ok 1 - set(ArrayRef[Str]) was called 2 time(s)';
verify($mock, times => 2)->set( ArrayRef[Str] );
test_test 'parameterized type works';

test_out 'ok 1 - set(ArrayRef|Int) was called 3 time(s)';
verify($mock, times => 3)->set( ArrayRef | Int );
test_test 'type union works';


test_out
'ok 1 - set(MooseX::Types::Structured::Tuple[Str,Str]) was called 1 time(s)';
verify($mock)->set( Tuple[Str,Str] );
test_test 'structured type works';
