# NAME

Test::Mocha - Test Spy/Stub Framework

# VERSION

version 0.20

# SYNOPSIS

Test::Mocha is a test spy framework for testing code that has dependencies on
other objects.

    use Test::More tests => 2;
    use Test::Mocha;
    use Types::Standard qw( Int );

    # create the mock
    my $warehouse = mock;

    # stub method calls (with type constraint for matching argument)
    stub($warehouse)->has_inventory($item1, Int)->returns(1);

    # execute the code under test
    my $order = Order->new(item => $item1, quantity => 50);
    $order->fill($warehouse);

    # verify interactions with the dependent object
    ok( $order->is_filled, 'Order is filled' );
    verify( $warehouse, '... and inventory is removed' )->remove_inventory($item1, 50);

    # clear the invocation history
    clear($warehouse);

# DESCRIPTION

We find all sorts of excuses to avoid writing tests for our code. Often it
seems too hard to isolate the code we want to test from the objects it is
dependent on. I'm too lazy and impatient to code my own mocks. Mocking
frameworks can help with this but they still take too long to set up the mock
objects. Enough setting up! I just want to get on with the actual testing.

Test::Mocha offers a simpler and more intuitive approach. Rather than setting
up the expected interactions beforehand, you ask questions about interactions
after the execution. The mocks can be created in almost no time. Yet they're
ready to be used out-of-the-box by pretending to be any type you want them to
be and accepting any method call on them.

Explicit stubbing is only required when the dependent object is expected to
return a specific response. And you can even use argument matchers to skip
having to enter the exact method arguments for the stub.

After executing the code under test, you can test that your code is interacting
correctly with its dependent objects. Selectively verify the method calls that
you are interested in only. As you verify behaviour, you focus on external
interfaces rather than on internal state.

# FUNCTIONS

## mock

    my $mock = mock;

`mock()` creates a new mock object. It's that quick and simple!

The mock object is ready, as-is, to pretend to be anything you want it to be.
Calling `isa()` or `does()` on the object will always return true. This
is particularly handy when dependent objects are required to satisfy type
constraint checks with OO frameworks such as [Moose](https://metacpan.org/module/Moose).

    ok( $mock->isa('AnyClass') );
    ok( $mock->does('AnyRole') );
    ok( $mock->DOES('AnyRole') );

It will also accept any method call on it. By default, method calls will
return `undef` (in scalar context) or an empty list (in list context).

    ok( $mock->can('any_method') );
    is( $mock->any_method(@args), undef );

You can stub `ref()` to specify the value it should return (see below for
more info about stubbing).

    stub($mock)->ref->returns('AnyClass');
    is( $mock->ref, 'AnyClass' );
    is( ref($mock), 'AnyClass' );

## stub

    stub($mock)->method(@args)->returns|dies|executes($response)

By default, the mock object already acts as a stub that accepts any method
call and returns `undef`. However, you can use `stub()` to tell a method to
give an alternative response. You can specify 3 types of responses:

- `returns(@values)`

    Specifies that a stub should return 1 or more values.

        stub($mock)->method(@args)->returns(1, 2, 3);
        is_deeply( [ $mock->method(@args) ], [ 1, 2, 3 ] );

- `dies($message)`

    Specifies that a stub should raise an exception.

        stub($mock)->method(@args)->dies('exception');
        ok( exception { $mock->method(@args) } );

- `executes($coderef)`

    Specifies that a stub should execute the given callback. The arguments used
    in the method call are passed on to the callback.

        my @returns = qw( first second third );

        stub($list)->get(Int)->executes(sub {
            my ($self, $i) = @_;
            die "index out of bounds" if $i < 0;
            return $returns[$i];
        });

        is( $list->get(0), 'first'  );
        is( $list->get(1), 'second' );
        is( $list->get(5), undef    );
        like( exception { $list->get(-1) }, qr/^index out of bounds/ ),

A stub applies to the exact method and arguments specified (but see also
["ARGUMENT MATCHING"](#ARGUMENT MATCHING) for a shortcut around this).

    stub($list)->get(0)->returns('first');
    stub($list)->get(1)->returns('second');

    is( $list->get(0), 'first' );
    is( $list->get(1), 'second' );
    is( $list->get(2), undef );

Chain responses together to provide a consecutive series.

    stub($iterator)->next
        ->returns(1)->returns(2)->returns(3)->dies('exhuasted');

    ok( $iterator->next == 1 );
    ok( $iterator->next == 2 );
    ok( $iterator->next == 3 );
    ok( exception { $iterator->next } );

The last stubbed response will persist until it is overridden.

    stub($warehouse)->has_inventory($item, 10)->returns(1);
    ok( $warehouse->has_inventory($item, 10) ) for 1 .. 5;

    stub($warehouse)->has_inventory($item, 10)->returns(0);
    ok( !$warehouse->has_inventory($item, 10) ) for 1 .. 5;

## verify

    verify($mock, [%option], [$test_name])->method(@args)

`verify()` is used to test the interactions with the mock object. You can use
it to verify that the correct methods were called, with the correct set of
arguments, and the correct number of times. `verify()` plays nicely with
[Test::Simple](https://metacpan.org/module/Test::Simple) and Co - it will print the test result along with your other
tests and calls to `verify()` are counted in the test plan.

    verify($warehouse)->remove($item, 50);
    # prints: ok 1 - remove("book", 50) was called 1 time(s)

An option may be specified to constrain the test.

- `times`

    Specifies the number of times the given method is expected to be called.
    The default is 1 if no other option is specified.

        verify( $mock, times => 3 )->method(@args)
        # print: ok 1 - method(@args) was called 3 time(s)

- `at_least`

    Specifies the minimum number of times the given method is expected to be
    called.

        verify( $mock, at_least => 3 )->method(@args)
        # print: ok 1 - method(@args) was called at least 3 time(s)

- `at_most`

    Specifies the maximum number of times the given method is expected to be
    called.

        verify( $mock, at_most => 5 )->method(@args)
        # print: ok 1 - method(@args) was called at most 5 time(s)

- `between`

    Specifies the minimum and maximum number of times the given method is
    expected to be called.

        verify( $mock, between => [3, 5] )->method(@args)
        # prints: ok 1 - method(@args) was called between 3 and 5 time(s)

An optional `$test_name` may be specified to be printed instead of the
default.

    verify( $warehouse, 'inventory removed' )->remove_inventory($item, 50);
    # prints: ok 1 - inventory removed

    verify( $warehouse, times => 0, 'inventory not removed' )->remove_inventory($item, 50);
    # prints: ok 2 - inventory not removed

## inspect

    @method_calls = inspect($mock)->method(@args)

    ( $method_call ) = inspect($warehouse)->remove_inventory(Str, Int);

    is( $method_call->name,            'remove_inventory' );
    is_deeply( [$method_call->args],   ['book', 50] );
    is_deeply( [$method_call->caller], ['test.pl', 5] );
    is( "$method_call", 'remove_inventory("book", 50) called at test.pl line 5' );

`inspect()` returns a list of method calls matching the given method call
specification. It can be useful for debugging failed `verify()` calls. Or use
it in place of a complex `verify()` call to break it down into smaller tests.

The method call objects have the following accessor methods:

- `name` - The name of the method called.
- `args` - The list of arguments passed to the method call.
- `caller` - The file and line number from which the method was called.

They are also `string` overloaded.

## inspect\_all

    @all_method_calls = inspect_all($mock)

`inspect_all()` returns a list containing all methods called on the mock
object. This is mainly used for debugging.

## clear

    clear($mock)

Clears the method call history of the mock for it to be reused in another test.
Note that this does not affect the stubbed methods.

# ARGUMENT MATCHING

Argument matchers may be used in place of specifying exact method arguments.
They allow you to be more general and will save you much time in your
method specifications to stubs and verifications. Argument matchers may be used
with `stub()`, `verify()` and `inspect`.

## Pre-defined types

You may use any of the ready-made types in [Types::Standard](https://metacpan.org/module/Types::Standard). (Alternatively,
Moose types like those in [MooseX::Types::Moose](https://metacpan.org/module/MooseX::Types::Moose) and
[MooseX::Types::Structured](https://metacpan.org/module/MooseX::Types::Structured) will also work.)

    use Types::Standard qw( Any );

    my $mock = mock;
    stub($mock)->foo(Any)->returns('ok');

    print $mock->foo(1);        # prints: ok
    print $mock->foo('string'); # prints: ok

    verify($mock, times => 2)->foo(Defined);
    # prints: ok 1 - foo(Defined) was called 2 time(s)

You may use the normal features of the types: parameterized and structured
types, and type unions, intersections and negations (but there's no need to
use coercions).

    use Types::Standard qw( Any ArrayRef HashRef Int StrMatch );

    my $list = mock;
    $list->set(1, [1,2]);
    $list->set(0, 'foobar');

    # parameterized type
    # prints: ok 1 - set(Int, StrMatch[(?^:^foo)]) was called 1 time(s)
    verify($list)->set( Int, StrMatch[qr/^foo/] );

## Self-defined types

You may also use your own types, defined using [Type::Utils](https://metacpan.org/module/Type::Utils).

    use Type::Utils -all;

    # naming the type means it will be printed nicely in the verify() output
    my $positive_int = declare 'PositiveInt', as Int, where { $_ > 0 };

    # prints: ok 2 - set(PositiveInt, Any) was called 1 time(s)
    verify($list)->set( $positive_int, Any );

## Argument slurping

`SlurpyArray` and `SlurpyHash` are special argument matchers exported by
Test::Mocha that you can use when you don't care what arguments are used.
They will just slurp up the remaining arguments as though they match.

    verify($list)->set( SlurpyArray );
    verify($list)->set( Int, SlurpyHash );

Because they consume the remaining arguments, you can't use further argument
validators after them. But you can, of course, use them before. Note also that
they will match empty argument lists.

# TO DO

- Enhanced verifications
- Module functions and class methods

# SUPPORT

## Bugs / Feature Requests

Please report any bugs or feature requests by email to `bug-test-mocha at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Mocha](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Mocha). You will be automatically notified of any
progress on the request by the system.

# AUTHOR

Steven Lee <stevenwh.lee@gmail.com>

# ACKNOWLEDGEMENTS

This module is a fork from [Test::Magpie](https://metacpan.org/module/Test::Magpie) originally written by Oliver
Charles (CYCLES).

It is inspired by the popular [Mockito](http://code.google.com/p/mockito/)
for Java and Python by Szczepan Faber.

# SEE ALSO

[Test::MockObject](https://metacpan.org/module/Test::MockObject)

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Lee.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
