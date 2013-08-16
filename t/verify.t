#!/usr/bin/perl -T
use strict;
use warnings;

use Test::More tests => 25;
use Test::Fatal;
use Test::Builder::Tester;

BEGIN { use_ok 'Test::Mocha' }

my $test_name;
my $file = __FILE__;
my $line;
my $err;

my $mock = mock;
$mock->once;
$mock->twice() for 1..2;

# -----------------
# simple verify() (with no options)

test_out 'ok 1 - once() was called 1 time(s)';
verify($mock)->once;
test_test 'simple verify() that passes';

$test_name = 'one() was called 1 time(s)';
$line = __LINE__ + 10;
test_out "not ok 1 - $test_name";
chomp($err = <<ERR);
#   Failed test '$test_name'
#   at $file line $line.
#          got: 0
#     expected: 1
ERR
test_err $err;
{
    verify($mock)->one;
}
test_test 'simple verify() that fails';

$test_name = 'once() was called once';
test_out "ok 1 - $test_name";
verify($mock, $test_name)->once;
test_test 'simple verify() with a test name';

test_out "ok 1 - $test_name";
verify($mock, times => 1, $test_name)->once;
test_test 'verify() with an option AND a name';

# -----------------
# verify() with 'times' option

test_out 'ok 1 - twice() was called 2 time(s)';
verify($mock, times => 2)->twice();
test_test "verify() with 'times' option that passes";

$test_name = 'twice() was called 1 time(s)';
$line = __LINE__ + 10;
test_out "not ok 1 - $test_name";
chomp($err = <<ERR);
#   Failed test '$test_name'
#   at $file line $line.
#          got: 2
#     expected: 1
ERR
test_err $err;
{
    verify($mock, times => 1)->twice;
}
test_test "verify() with 'times' option that fails";

like exception { verify($mock, times => 'string') },
    qr/^'times' option must be a number/,
    "verify() with invalid 'times' value";

# -----------------
# verify() with 'at_least' option

test_out 'ok 1 - once() was called at least 1 time(s)';
verify($mock, at_least => 1)->once;
test_test "verify() with 'at_least' option that passes";

$test_name = 'once() was called at least 2 time(s)';
$line = __LINE__ + 11;
test_out "not ok 1 - $test_name";
chomp($err = <<ERR);
#   Failed test '$test_name'
#   at $file line $line.
#     '1'
#         >=
#     '2'
ERR
test_err $err;
{
    verify($mock, at_least => 2)->once;
}
test_test "verify() with 'at_least' option that fails";

like exception { verify($mock, at_least => 'string') },
    qr/^'at_least' option must be a number/,
    "verify() with invalid 'at_least' value";

# -----------------
# verify() with 'at_most' option

test_out 'ok 1 - twice() was called at most 2 time(s)';
verify($mock, at_most => 2)->twice;
test_test "verify() with 'at_most' option that passes";

$test_name = 'twice() was called at most 1 time(s)';
$line = __LINE__ + 11;
test_out "not ok 1 - $test_name";
chomp($err = <<ERR);
#   Failed test '$test_name'
#   at $file line $line.
#     '2'
#         <=
#     '1'
ERR
test_err $err;
{
    verify($mock, at_most => 1)->twice;
}
test_test "verify() with 'at_most' option that fails";

like exception { verify($mock, at_most => 'string') },
    qr/^'at_most' option must be a number/,
    "verify() with invalid 'at_most' value";

# -----------------
# verify() with 'between' option

test_out 'ok 1 - twice() was called between 1 and 2 time(s)';
verify($mock, between => [1, 2])->twice;
test_test "verify() with 'between' option that passes (lower boundary)";

test_out 'ok 1 - twice() was called between 2 and 3 time(s)';
verify($mock, between => [2, 3])->twice;
test_test "verify() with 'between' option that passes (upper boundary)";

test_out 'not ok 1 - twice() was called between 0 and 1 time(s)';
test_fail +1;
verify($mock, between => [0, 1])->twice;
test_test "verify() with 'between' option that fails (lower boundary)";

test_out 'not ok 1 - twice() was called between 3 and 4 time(s)';
test_fail +1;
verify($mock, between => [3, 4])->twice;
test_test "verify() with 'between' option that fails (upper boundary)";

like exception { verify($mock, between => 1)->twice },
    qr/'between' option must be an arrayref with 2 numbers in ascending order/,
    "verify() with invalid 'between' value (not an arrayref)";

like exception { verify($mock, between => [1])->twice },
    qr/'between' option must be an arrayref with 2 numbers in ascending order/,
    "verify() with invalid 'between' value (not a pair)";

like exception { verify($mock, between => ['one', 'two'])->twice },
    qr/'between' option must be an arrayref with 2 numbers in ascending order/,
    "verify() with invalid 'between' value (pair are not numbers)";

like exception { verify($mock, between => [2, 1])->twice },
    qr/'between' option must be an arrayref with 2 numbers in ascending order/,
    "verify() with invalid 'between' value (pair not ordered)";

# -----------------
# verify() exceptions

like exception { verify() },
    qr/^verify\(\) must be given a mock object/,
    'verify() called without an argument';

like exception { verify('string') },
    qr/^verify\(\) must be given a mock object/,
    'verify() called with an invalid argument';

like exception {verify($mock, times => 2, at_least => 2, at_most => 2)->twice},
    qr/^You can set only one of these options:/,
    'verify() called with multiple options';

