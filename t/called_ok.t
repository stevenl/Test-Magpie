#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 38;
use Test::Fatal;
use Test::Builder::Tester;
use Types::Standard qw( Any slurpy );

BEGIN { use_ok 'Test::Mocha' }

my $test_name;
my $file = __FILE__;
my $line;
my $err;
my $e;

my $mock = mock;
$mock->once;
$mock->twice() for 1 .. 2;
$mock->thrice($_) for 1 .. 3;

my $diag_call_history = <<"END";
# Complete method call history (most recent call last):
#     once() called at $file line 20
#     twice() called at $file line 21
#     twice() called at $file line 21
#     thrice(1) called at $file line 22
#     thrice(2) called at $file line 22
#     thrice(3) called at $file line 22
END
chomp $diag_call_history;

# -----------------
# simple called_ok() (with no times() specified)

test_out('ok 1 - once() was called 1 time(s)');
called_ok { $mock->once };
test_test('simple called_ok() that passes');

$test_name = 'one() was called 1 time(s)';
$line      = __LINE__ + 12;
test_out("not ok 1 - $test_name");
chomp( $err = <<"ERR" );
#   Failed test '$test_name'
#   at $file line $line.
# Error: unexpected number of calls to 'one()'
#          got: 0 time(s)
#     expected: 1 time(s)
$diag_call_history
ERR
test_err($err);
{
    called_ok { $mock->one };
}
test_test('simple called_ok() that fails');

$test_name = 'once() was called once';
test_out("ok 1 - $test_name");
{
    called_ok { $mock->once } $test_name;
}
test_test('simple called_ok() with a test name');

my $new = mock;
$test_name = 'never_called() was called 1 time(s)';
$line      = __LINE__ + 13;
test_out("not ok 1 - $test_name");
chomp( $err = <<"ERR" );
#   Failed test '$test_name'
#   at $file line $line.
# Error: unexpected number of calls to 'never_called()'
#          got: 0 time(s)
#     expected: 1 time(s)
# Complete method call history (most recent call last):
#     (No methods were called)
ERR
test_err($err);
{
    called_ok { $new->never_called };
}
test_test('diagnostics with no method call history');

# -----------------
# called_ok() with times()

test_out('ok 1 - twice() was called 2 time(s)');
called_ok { $mock->twice } &times(2);
test_test("called_ok() with times() that passes");

$test_name = 'twice() was called 1 time(s)';
$line      = __LINE__ + 12;
test_out("not ok 1 - $test_name");
chomp( $err = <<"ERR" );
#   Failed test '$test_name'
#   at $file line $line.
# Error: unexpected number of calls to 'twice()'
#          got: 2 time(s)
#     expected: 1 time(s)
$diag_call_history
ERR
test_err($err);
{
    called_ok { $mock->twice } &times(1);
}
test_test("called_ok() with times() that fails");

like(
    $e = exception {
        called_ok { $mock->once } &times('string');
    },
    qr/^times\(\) must be given a number/,
    "called_ok with invalid times() value"
);
like( $e, qr/at \Q$file\E/, '... and error traces back to this script' );

# -----------------
# called_ok() with atleast()

test_out('ok 1 - once() was called at least 1 time(s)');
called_ok { $mock->once } atleast(1);
test_test("called_ok() with atleast() that passes");

$test_name = 'once() was called at least 2 time(s)';
$line      = __LINE__ + 12;
test_out("not ok 1 - $test_name");
chomp( $err = <<"ERR" );
#   Failed test '$test_name'
#   at $file line $line.
# Error: unexpected number of calls to 'once()'
#          got: 1 time(s)
#     expected: at least 2 time(s)
$diag_call_history
ERR
test_err($err);
{
    called_ok { $mock->once } atleast(2);
}
test_test("called_ok() with atleast() that fails");

like(
    $e = exception {
        called_ok { $mock->twice } atleast('once');
    },
    qr/^atleast\(\) must be given a number/,
    "called_ok() with invalid atleast() value"
);
like( $e, qr/at \Q$file\E/, '... and error traces back to this script' );

# -----------------
# called_ok() with atmost()

test_out('ok 1 - twice() was called at most 2 time(s)');
called_ok { $mock->twice } atmost(2);
test_test("called_ok() with atmost() that passes");

$test_name = 'twice() was called at most 1 time(s)';
$line      = __LINE__ + 12;
test_out("not ok 1 - $test_name");
chomp( $err = <<"ERR" );
#   Failed test '$test_name'
#   at $file line $line.
# Error: unexpected number of calls to 'twice()'
#          got: 2 time(s)
#     expected: at most 1 time(s)
$diag_call_history
ERR
test_err($err);
{
    called_ok { $mock->twice } atmost(1);
}
test_test("called_ok() with atmost() that fails");

like(
    $e = exception {
        called_ok { $mock->twice } atmost('thrice');
    },
    qr/^atmost\(\) must be given a number/,
    "called_ok() with invalid atmost() value"
);
like( $e, qr/at \Q$file\E/, '... and error traces back to this script' );

# -----------------
# called_ok() with between()

test_out('ok 1 - twice() was called between 1 and 2 time(s)');
called_ok { $mock->twice } between( 1, 2 );
test_test("called_ok() with between() that passes (lower boundary)");

test_out('ok 1 - twice() was called between 2 and 3 time(s)');
called_ok { $mock->twice } between( 2, 3 );
test_test("called_ok() with between() that passes (upper boundary)");

$test_name = 'twice() was called between 0 and 1 time(s)';
$line      = __LINE__ + 12;
test_out("not ok 1 - $test_name");
chomp( $err = <<"ERR" );
#   Failed test '$test_name'
#   at $file line $line.
# Error: unexpected number of calls to 'twice()'
#          got: 2 time(s)
#     expected: between 0 and 1 time(s)
$diag_call_history
ERR
test_err($err);
{
    called_ok { $mock->twice } between( 0, 1 );
}
test_test("called_ok() with between() that fails (lower boundary)");

$test_name = 'twice() was called between 3 and 4 time(s)';
$line      = __LINE__ + 12;
test_out("not ok 1 - $test_name");
chomp( $err = <<"ERR" );
#   Failed test '$test_name'
#   at $file line $line.
# Error: unexpected number of calls to 'twice()'
#          got: 2 time(s)
#     expected: between 3 and 4 time(s)
$diag_call_history
ERR
test_err($err);
{
    called_ok { $mock->twice } between( 3, 4 );
}
test_test("called_ok() with between() that fails (upper boundary)");

like(
    exception {
        called_ok { $mock->twice } between( 'one', 'two' );
    },
    qr/between\(\) must be given 2 numbers in ascending order/,
    "called_ok() with invalid between() value (pair are not numbers)"
);

like(
    $e = exception {
        called_ok { $mock->twice } between( 2, 1 );
    },
    qr/between\(\) must be given 2 numbers in ascending order/,
    "called_ok() with invalid between() value (pair not ordered)"
);
like( $e, qr/at \Q$file\E/, '... and error traces back to this script' );

# -----------------
# called_ok() with an option AND a name

$test_name = 'name for my test';
test_out("ok 1 - $test_name");
called_ok { $mock->once } &times(1), $test_name;
test_test("called_ok() with times() and a name");

test_out("ok 1 - $test_name");
called_ok { $mock->once } atleast(1), $test_name;
test_test("called_ok() with atleast() and a name");

test_out("ok 1 - $test_name");
called_ok { $mock->twice } atmost(2), $test_name;
test_test("called_ok() with atmost() and a name");

test_out("ok 1 - $test_name");
called_ok { $mock->twice } between( 1, 2 ), $test_name;
test_test("called_ok() with between() and a name");

# -----------------
# called_ok() with type constraint arguments

test_out('ok 1 - thrice(Any) was called 3 time(s)');
called_ok { $mock->thrice(Any) } &times(3);
test_test('called_ok() accepts type constraints');

like(
    $e = exception {
        called_ok { $mock->thrice( SlurpyArray, 1 ) };
    },
    qr/^No arguments allowed after a slurpy type constraint/,
    'Disallow arguments after a slurpy type constraint'
);
like( $e, qr/at \Q$file\E/, '... and error traces back to this script' );

# to complete test coverage - once() has no arguments
like(
    $e = exception {
        called_ok { $mock->once( SlurpyArray, 1 ) };
    },
    qr/^No arguments allowed after a slurpy type constraint/,
    'Disallow arguments after a slurpy type constraint'
);
like( $e, qr/at \Q$file\E/, '... and error traces back to this script' );

like(
    $e = exception {
        called_ok { $mock->thrice( slurpy Any ) };
    },
    qr/^Slurpy argument must be a type of ArrayRef or HashRef/,
    'Invalid Slurpy argument for called_ok()'
);
like( $e, qr/at \Q$file\E/, '... and error traces back to this script' );

# -----------------
# conditional verifications - verify that failure diagnostics are not output

$test_name = 'method_not_called() was called 1 time(s)';
$line      = __LINE__ + 9;
chomp( my $out = <<"OUT" );
not ok 1 - $test_name # TODO should fail
#   Failed (TODO) test '$test_name'
#   at $file line $line.
OUT
test_out($out);
TODO: {
    local $TODO = "should fail";
    called_ok { $mock->method_not_called };
}
test_test('called_ok() in a TODO block');

$test_name = "a verification in skip block";
test_out("ok 1 # skip $test_name");
SKIP: {
    skip $test_name, 1;
    called_ok { $mock->method_not_called };
}
test_test('called_ok() in a SKIP block');

test_out("not ok 1 # TODO & SKIP $test_name");
TODO: {
    todo_skip $test_name, 1;
    called_ok { $mock->method_not_called };
}
test_test('called_ok() in a TODO_SKIP block');
