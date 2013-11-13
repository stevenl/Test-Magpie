#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 47;
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
# called_ok() exceptions

like(
    $e = exception { called_ok() },
    qr/^called_ok\(\) must be given a coderef/,
    'called_ok() expects an argument'
);
like(
    $e = exception { called_ok('string') },
    qr/^called_ok\(\) must be given a coderef/,
    '... and argument must be a coderef'
);
like(
    $e, qr/at \Q$file\E/,
    '... and error traces back to this script'
);

$e = exception {
    called_ok( sub { $mock->twice }, times => 2, at_least => 2 )
};
like(
    $e, qr/^You can set only one of these options:/,
    'called_ok() cannot be given multiple options'
);
like(
    $e, qr/at \Q$file\E/,
    '... and error traces back to this script'
);

like(
    $e = exception { called_ok( sub { $mock->once }, tiny => 1 ) },
    qr/^called_ok\(\) was given an invalid option: 'tiny'/,
    'called_ok() called with an invalid option'
);
like(
    $e, qr/at \Q$file\E/,
    '... and error traces back to this script'
);

# -----------------
# simple called_ok() (with no options)

test_out('ok 1 - once() was called 1 time(s)');
called_ok( sub { $mock->once } );
test_test('simple called_ok() that passes');

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
test_err($err);
{
    called_ok( sub { $mock->one } );
}
test_test('simple called_ok() that fails');

$test_name = 'once() was called once';
test_out("ok 1 - $test_name");
{
    called_ok( sub { $mock->once }, $test_name );
}
test_test('simple called_ok() with a test name');

my $new = mock;
$test_name = 'never_called() was called 1 time(s)';
$line = __LINE__ + 13;
test_out("not ok 1 - $test_name");
chomp($err = <<ERR);
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
    called_ok( sub { $new->never_called } );
}
test_test('diagnostics with no method call history');

# -----------------
# called_ok() with 'times' option

test_out('ok 1 - twice() was called 2 time(s)');
called_ok( sub { $mock->twice }, times => 2 );
test_test("called_ok() with 'times' option that passes");

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
test_err($err);
{
    called_ok( sub { $mock->twice }, times => 1 );
}
test_test("called_ok() with 'times' option that fails");

like(
    $e = exception { called_ok( sub { $mock->once }, times => 'string') },
    qr/^'times' option must be a number/,
    "called_ok() with invalid 'times' value"
);
like(
    $e, qr/at \Q$file\E/,
    '... and error traces back to this script'
);

# -----------------
# called_ok() with 'at_least' option

test_out('ok 1 - once() was called at least 1 time(s)');
called_ok( sub { $mock->once }, at_least => 1 );
test_test("called_ok() with 'at_least' option that passes");

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
test_err($err);
{
    called_ok( sub { $mock->once }, at_least => 2 );
}
test_test("called_ok() with 'at_least' option that fails");

like(
    $e = exception { called_ok( sub { $mock->twice }, at_least => 'once') },
    qr/^'at_least' option must be a number/,
    "called_ok() with invalid 'at_least' value"
);
like(
    $e, qr/at \Q$file\E/,
    '... and error traces back to this script'
);

# -----------------
# called_ok() with 'at_most' option

test_out('ok 1 - twice() was called at most 2 time(s)');
called_ok( sub { $mock->twice }, at_most => 2 );
test_test("called_ok() with 'at_most' option that passes");

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
test_err($err);
{
    called_ok( sub { $mock->twice }, at_most => 1 );
}
test_test("called_ok() with 'at_most' option that fails");

like(
    $e = exception { called_ok( sub { $mock->twice }, at_most => 'thrice') },
    qr/^'at_most' option must be a number/,
    "called_ok() with invalid 'at_most' value"
);
like(
    $e, qr/at \Q$file\E/,
    '... and error traces back to this script'
);

# -----------------
# called_ok() with 'between' option

test_out('ok 1 - twice() was called between 1 and 2 time(s)');
called_ok( sub { $mock->twice }, between => [1, 2] );
test_test("called_ok() with 'between' option that passes (lower boundary)");

test_out('ok 1 - twice() was called between 2 and 3 time(s)');
called_ok( sub { $mock->twice }, between => [2, 3] );
test_test("called_ok() with 'between' option that passes (upper boundary)");

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
test_err($err);
{
    called_ok( sub { $mock->twice }, between => [0, 1] );
}
test_test("called_ok() with 'between' option that fails (lower boundary)");

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
test_err($err);
{
    called_ok( sub { $mock->twice }, between => [3, 4] );
}
test_test("called_ok() with 'between' option that fails (upper boundary)");

like(
    exception { called_ok( sub { $mock->twice }, between => 1) },
    qr/'between' option must be an arrayref with 2 numbers in ascending order/,
    "called_ok() with invalid 'between' value (not an arrayref)"
);

like(
    exception { called_ok( sub { $mock->twice }, between => [1]) },
    qr/'between' option must be an arrayref with 2 numbers in ascending order/,
    "called_ok() with invalid 'between' value (not a pair)"
);

like(
    exception { called_ok( sub { $mock->twice }, between => ['one', 'two']) },
    qr/'between' option must be an arrayref with 2 numbers in ascending order/,
    "called_ok() with invalid 'between' value (pair are not numbers)"
);

like(
    $e = exception { called_ok( sub { $mock->twice }, between => [2, 1]) },
    qr/'between' option must be an arrayref with 2 numbers in ascending order/,
    "called_ok() with invalid 'between' value (pair not ordered)"
);
like(
    $e, qr/at \Q$file\E/,
    '... and error traces back to this script'
);

# -----------------
# called_ok() with an option AND a name

$test_name = 'name for my test';
test_out("ok 1 - $test_name");
called_ok( sub { $mock->once }, times => 1, $test_name );
test_test("called_ok() with 'times' option and a name");

test_out("ok 1 - $test_name");
called_ok( sub { $mock->once }, at_least => 1, $test_name );
test_test("called_ok() with 'at_least' option and a name");

test_out("ok 1 - $test_name");
called_ok( sub { $mock->twice }, at_most => 2, $test_name );
test_test("called_ok() with 'at_most' option and a name");

test_out("ok 1 - $test_name");
called_ok( sub { $mock->twice }, between => [1, 2], $test_name );
test_test("called_ok() with 'between' option and a name");

# -----------------
# called_ok() with type constraint arguments

test_out('ok 1 - thrice(Any) was called 3 time(s)');
called_ok( sub { $mock->thrice(Any) }, times => 3 );
test_test('called_ok() accepts type constraints');

like(
    $e = exception { called_ok( sub { $mock->thrice(SlurpyArray, 1) } ) },
    qr/^No arguments allowed after a slurpy type constraint/,
    'Disallow arguments after a slurpy type constraint'
);
like(
    $e, qr/at \Q$file\E/,
    '... and error traces back to this script'
);

# to complete test coverage - once() has no arguments
like(
    $e = exception { called_ok( sub { $mock->once(SlurpyArray, 1) } ) },
    qr/^No arguments allowed after a slurpy type constraint/,
    'Disallow arguments after a slurpy type constraint'
);
like(
    $e, qr/at \Q$file\E/,
    '... and error traces back to this script'
);

like(
    $e = exception { called_ok( sub { $mock->thrice(slurpy Any) } ) },
    qr/^Slurpy argument must be a type of ArrayRef or HashRef/,
    'Invalid Slurpy argument for called_ok()'
);
like(
    $e, qr/at \Q$file\E/,
    '... and error traces back to this script'
);

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
    called_ok( sub { $mock->method_not_called } );
}
test_test('called_ok() in a TODO block');

$test_name = "a verification in skip block";
test_out("ok 1 # skip $test_name");
SKIP: {
    skip $test_name, 1;
    called_ok( sub { $mock->method_not_called } );
}
test_test('called_ok() in a SKIP block');

test_out("not ok 1 # TODO & SKIP $test_name");
TODO: {
    todo_skip $test_name, 1;
    called_ok( sub { $mock->method_not_called } );
}
test_test('called_ok() in a TODO_SKIP block');
