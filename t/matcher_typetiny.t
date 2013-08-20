#!perl -T
use strict;
use warnings;

use Test::More tests => 11;
use Test::Builder::Tester;
use Test::Fatal;

use Type::Utils -all;
use Types::Standard qw( Any Int Str StrMatch Tuple );

BEGIN { use_ok 'Test::Mocha' }

my $mock = mock;

$mock->set('foo');
$mock->set('foobar');
$mock->set(+1, 'not an int');
$mock->set(-1, 'negative');
$mock->set( [qw( foo bar )] );

my $e = exception { $mock->foo(1, Int) };
like $e, qr/Int/,
    'mock does not accept method calls with type constraint arguments';
like $e, qr/matcher_typetiny\.t/, ' and message traces back to this script';

stub($mock)->set(Any)->returns('any');
is $mock->set(1), 'any', 'stub() accepts type constraints';

test_out 'ok 1 - set(Int) was called 1 time(s)';
verify($mock)->set(Int);
test_test 'verify() accepts type constraints';

test_out 'ok 1 - set(StrMatch[(?^:^foo)]) was called 2 time(s)';
verify($mock, times => 2)->set( StrMatch[qr/^foo/] );
test_test 'parameterized type works';

test_out 'ok 1 - set(Int, ~Int) was called 2 time(s)';
verify($mock, times => 2)->set(Int, ~Int);
test_test 'type negation works';

test_out 'ok 1 - set(Int|Str) was called 3 time(s)';
verify($mock, times => 3)->set( Int | Str );
test_test 'type union works';

test_out
'ok 1 - set(StrMatch[(?^:^foo)]&StrMatch[(?^:bar$)]) was called 1 time(s)';
verify($mock)->set(StrMatch[qr/^foo/] & StrMatch[qr/bar$/]);
test_test 'type intersection works';

test_out 'ok 1 - set(Tuple[Str,Str]) was called 1 time(s)';
verify($mock)->set( Tuple[Str,Str] );
test_test 'structured type works';

my $positive_int = declare 'PositiveInt', as Int, where { $_ > 0 };
test_out 'ok 1 - set(PositiveInt, Str) was called 1 time(s)';
verify($mock)->set($positive_int, Str);
test_test 'self-defined type constraint works';