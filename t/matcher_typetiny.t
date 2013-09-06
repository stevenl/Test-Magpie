#!perl -T
use strict;
use warnings;

use Test::More tests => 14;
use Test::Builder::Tester;
use Test::Fatal;

use Type::Utils -all;
use Types::Standard -all;

BEGIN { use_ok 'Test::Mocha' }

my $mock = mock;

$mock->set('foo');
$mock->set('foobar');
$mock->set(+1, 'not an int');
$mock->set(-1, 'negative');
$mock->set( [qw( foo bar )] );

test_out
qr/ok 1 - set\(StrMatch\[\(\?.*\:\^foo\)\]\) was called 2 time\(s\)\s/;
verify($mock, times => 2)->set( StrMatch[qr/^foo/] );
test_test 'parameterized type works';

test_out 'ok 1 - set(Int, ~Int) was called 2 time(s)';
verify($mock, times => 2)->set(Int, ~Int);
test_test 'type negation works';

test_out 'ok 1 - set(Int|Str) was called 2 time(s)';
verify($mock, times => 2)->set( Int | Str );
test_test 'type union works';

test_out
qr/ok 1 - set\(StrMatch\[\(\?.*\:\^foo\)\]\&StrMatch\[\(\?.*\:bar\$\)\]\) was called 1 time\(s\)\s/;
verify($mock)->set( StrMatch[qr/^foo/] & StrMatch[qr/bar$/] );
test_test 'type intersection works';

test_out 'ok 1 - set(Tuple[Str,Str]) was called 1 time(s)';
verify($mock)->set( Tuple[Str,Str] );
test_test 'structured type works';

my $positive_int = declare 'PositiveInt', as Int, where { $_ > 0 };
test_out 'ok 1 - set(PositiveInt, Str) was called 1 time(s)';
verify($mock)->set($positive_int, Str);
test_test 'self-defined type constraint works';

# -----------------------
# slurpy type constraints

test_out 'ok 1 - set({ slurpy: ArrayRef }) was called 5 time(s)';
verify($mock, times => 5)->set( slurpy ArrayRef );
test_test 'slurpy ArrayRef works';

test_out 'ok 1 - set({ slurpy: Tuple[Defined,Defined] }) was called 2 time(s)';
verify($mock, times => 2)->set( slurpy Tuple[Defined,Defined] );
test_test 'slurpy Tuple works';

test_out 'ok 1 - set({ slurpy: HashRef }) was called 2 time(s)';
verify($mock, times => 2)->set( slurpy HashRef );
test_test 'slurpy HashRef works';

test_out 'ok 1 - set({ slurpy: Dict[-1=>Str] }) was called 1 time(s)';
verify($mock, times => 1)->set( slurpy Dict[-1 => Str] );
test_test 'slurpy Dict works';

test_out 'ok 1 - set({ slurpy: Map[PositiveInt,Str] }) was called 1 time(s)';
verify($mock, times => 1)->set( slurpy Map[$positive_int, Str] );
test_test 'slurpy Map works';

# slurpy matches with empty argument list
$mock->bar();
test_out 'ok 1 - bar({ slurpy: ArrayRef }) was called 1 time(s)';
verify($mock)->bar( slurpy ArrayRef );
test_test 'slurpy ArrayRef matches no arguments';

test_out 'ok 1 - bar({ slurpy: HashRef }) was called 1 time(s)';
verify($mock)->bar( slurpy HashRef );
test_test 'slurpy HashRef matches no arguments';

# -----------------------
# undef edge cases
#
# These tests are invalid because they are inconsistent with Type::Params and
# they are counter-intuitive.
#
# clear($mock);
# $mock->set();
#
# test_out 'ok 1 - set(Defined) was called 0 time(s)';
# verify($mock, times => 0)->set(Defined);
# test_test 'Defined does not match undef';
#
# test_out 'ok 1 - set(Any) was called 1 time(s)';
# verify($mock)->set(Any);
# test_test 'Any matches undef';
#
# test_out 'ok 1 - set(~Int) was called 1 time(s)';
# verify($mock)->set(~Int);
# test_test 'negated type matches undef';
#
# test_out 'ok 1 - set({ slurpy: ArrayRef }) was called 1 time(s)';
# verify($mock)->set( slurpy ArrayRef );
# test_test 'slurpy ArrayRef[Any] matches undef';
