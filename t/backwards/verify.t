#!/usr/bin/perl -T

use strict;
use warnings;
no warnings 'deprecated';

use Test::More tests => 40;
use Test::Fatal;
use Test::Builder::Tester;
use Types::Standard qw( Any slurpy );

BEGIN { use_ok 'Test::Mocha' }

my $test_name;
my $file = __FILE__;
my $line;
my $err;

my $mock = mock;
$mock->once;
$mock->twice() for 1..2;
$mock->thrice($_) for 1..3;

my $diag_call_history = <<END;
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
# verify() exceptions

like(
    exception { verify() },
    qr/^verify\(\) must be given a mock object/,
    'verify() called without an argument'
);

like(
    exception { verify('string') },
    qr/^verify\(\) must be given a mock object/,
    'verify() called with an invalid argument'
);

like(
    exception { verify($mock, times => 2, at_least => 2)->twice },
    qr/^You can set only one of these options:/,
    'verify() called with multiple options'
);

like(
    exception { verify($mock, tiny => 1)->once },
    qr/^called_ok\(\) was given an invalid option: 'tiny'/,
    'verify() called with an invalid option'
);

# -----------------
# simple verify() (with no options)

test_out('ok 1 - once() was called 1 time(s)');
verify($mock)->once;
test_test('simple verify() that passes');

$test_name = 'one() was called 1 time(s)';
$line = __LINE__ + 12;
test_out("not ok 1 - $test_name");
chomp($err = <<ERR);
#   Failed test '$test_name'
#   at $file line $line.
# Error: unexpected number of calls to 'one()'
#          got: 0 time(s)
#     expected: 1 time(s)
$diag_call_history
ERR
test_err $err;
{
    verify($mock)->one;
}
test_test('simple verify`() that fails');

$test_name = 'once() was called once';
test_out("ok 1 - $test_name");
verify($mock, $test_name)->once;
test_test('simple verify() with a test name');

# -----------------
# verify() with 'times' option

test_out('ok 1 - twice() was called 2 time(s)');
verify($mock, times => 2)->twice();
test_test("verify() with 'times' option that passes");

$test_name = 'twice() was called 1 time(s)';
$line = __LINE__ + 12;
test_out("not ok 1 - $test_name");
chomp($err = <<ERR);
#   Failed test '$test_name'
#   at $file line $line.
# Error: unexpected number of calls to 'twice()'
#          got: 2 time(s)
#     expected: 1 time(s)
$diag_call_history
ERR
test_err $err;
{
    verify($mock, times => 1)->twice;
}
test_test("verify() with 'times' option that fails");

like(
    exception { verify($mock, times => 'string') },
    qr/^'times' option must be a number/,
    "verify() with invalid 'times' value"
);

# -----------------
# verify() with 'at_least' option

test_out('ok 1 - once() was called at least 1 time(s)');
verify($mock, at_least => 1)->once;
test_test("verify() with 'at_least' option that passes");

$test_name = 'once() was called at least 2 time(s)';
$line = __LINE__ + 12;
test_out("not ok 1 - $test_name");
chomp($err = <<ERR);
#   Failed test '$test_name'
#   at $file line $line.
# Error: unexpected number of calls to 'once()'
#          got: 1 time(s)
#     expected: at least 2 time(s)
$diag_call_history
ERR
test_err $err;
{
    verify($mock, at_least => 2)->once;
}
test_test("verify() with 'at_least' option that fails");

like(
    exception { verify($mock, at_least => 'string') },
    qr/^'at_least' option must be a number/,
    "verify() with invalid 'at_least' value"
);

# -----------------
# verify() with 'at_most' option

test_out('ok 1 - twice() was called at most 2 time(s)');
verify($mock, at_most => 2)->twice;
test_test("verify() with 'at_most' option that passes");

$test_name = 'twice() was called at most 1 time(s)';
$line = __LINE__ + 12;
test_out("not ok 1 - $test_name");
chomp($err = <<ERR);
#   Failed test '$test_name'
#   at $file line $line.
# Error: unexpected number of calls to 'twice()'
#          got: 2 time(s)
#     expected: at most 1 time(s)
$diag_call_history
ERR
test_err $err;
{
    verify($mock, at_most => 1)->twice;
}
test_test("verify() with 'at_most' option that fails");

like(
    exception { verify($mock, at_most => 'string') },
    qr/^'at_most' option must be a number/,
    "verify() with invalid 'at_most' value"
);

# -----------------
# verify() with 'between' option

test_out('ok 1 - twice() was called between 1 and 2 time(s)');
verify($mock, between => [1, 2])->twice;
test_test("verify() with 'between' option that passes (lower boundary)");

test_out('ok 1 - twice() was called between 2 and 3 time(s)');
verify($mock, between => [2, 3])->twice;
test_test("verify() with 'between' option that passes (upper boundary)");

$test_name = 'twice() was called between 0 and 1 time(s)';
$line = __LINE__ + 12;
test_out("not ok 1 - $test_name");
chomp($err = <<ERR);
#   Failed test '$test_name'
#   at $file line $line.
# Error: unexpected number of calls to 'twice()'
#          got: 2 time(s)
#     expected: between 0 and 1 time(s)
$diag_call_history
ERR
test_err $err;
{
    verify($mock, between => [0, 1])->twice;
}
test_test("verify() with 'between' option that fails (lower boundary)");

$test_name = 'twice() was called between 3 and 4 time(s)';
$line = __LINE__ + 12;
test_out("not ok 1 - $test_name");
chomp($err = <<ERR);
#   Failed test '$test_name'
#   at $file line $line.
# Error: unexpected number of calls to 'twice()'
#          got: 2 time(s)
#     expected: between 3 and 4 time(s)
$diag_call_history
ERR
test_err $err;
{
    verify($mock, between => [3, 4])->twice;
}
test_test("verify() with 'between' option that fails (upper boundary)");

like(
    exception { verify($mock, between => 1)->twice },
    qr/'between' option must be an arrayref with 2 numbers in ascending order/,
    "verify() with invalid 'between' value (not an arrayref)"
);

like(
    exception { verify($mock, between => [1])->twice },
    qr/'between' option must be an arrayref with 2 numbers in ascending order/,
    "verify() with invalid 'between' value (not a pair)"
);

like(
    exception { verify($mock, between => ['one', 'two'])->twice },
    qr/'between' option must be an arrayref with 2 numbers in ascending order/,
    "verify() with invalid 'between' value (pair are not numbers)"
);

like(
    exception { verify($mock, between => [2, 1])->twice },
    qr/'between' option must be an arrayref with 2 numbers in ascending order/,
    "verify() with invalid 'between' value (pair not ordered)"
);

# -----------------
# verify() with an option AND a name

$test_name = 'name for my test';
test_out("ok 1 - $test_name");
verify($mock, times => 1, $test_name)->once;
test_test("verify() with 'times' option and a name");

test_out("ok 1 - $test_name");
verify($mock, at_least => 1, $test_name)->once;
test_test("verify() with 'at_least' option and a name");

test_out("ok 1 - $test_name");
verify($mock, at_most => 2, $test_name)->twice;
test_test("verify() with 'at_most' option and a name");

test_out("ok 1 - $test_name");
verify($mock, between => [1, 2], $test_name)->twice;
test_test("verify() with 'between' option and a name");

# -----------------
# verify() with type constraint arguments

test_out('ok 1 - thrice(Any) was called 3 time(s)');
verify($mock, times => 3)->thrice(Any);
test_test('verify() accepts type constraints');

my $e = exception { verify($mock)->thrice(SlurpyArray, 1) };
like(
    $e, qr/^No arguments allowed after a slurpy type constraint/,
    'Disallow arguments after a slurpy type constraint'
);
like( $e, qr/verify\.t/, '... and message traces back to this script' );

# to complete test coverage - once() has no arguments
$e = exception { verify($mock)->once(SlurpyArray, 1) };
like(
    $e, qr/^No arguments allowed after a slurpy type constraint/,
    'Disallow arguments after a slurpy type constraint'
);
like( $e, qr/verify\.t/, '... and message traces back to this script' );

$e = exception { verify($mock)->thrice(slurpy Any) };
like(
    $e, qr/^Slurpy argument must be a type of ArrayRef or HashRef/,
    'Invalid Slurpy argument for verify()'
);
like( $e, qr/verify\.t/, '... and message traces back to this script' );

# -----------------
# conditional verifications - verify that failure diagnostics are not output

$test_name = 'method_not_called() was called 1 time(s)';
$line = __LINE__ + 9;
chomp(my $out = <<OUT);
not ok 1 - $test_name # TODO should fail
#   Failed (TODO) test '$test_name'
#   at $file line $line.
OUT
test_out($out);
TODO: {
    local $TODO = "should fail";
    verify($mock)->method_not_called;
}
test_test('verify() in a TODO block');

$test_name = "a verification in skip block";
test_out("ok 1 # skip $test_name");
SKIP: {
    skip $test_name, 1;
    verify($mock)->method_not_called;
}
test_test('verify() in a SKIP block');

test_out("not ok 1 # TODO & SKIP $test_name");
TODO: {
    todo_skip $test_name, 1;
    verify($mock)->method_not_called;
}
test_test('verify() in a TODO_SKIP block');

test_out;
verify($mock)->DESTROY;
test_test('DESTROY() is not AUTOLOADed');
