use strict;
use warnings;
package Test::Mocha;
# ABSTRACT: Test Spy/Stub Framework

=head1 SYNOPSIS

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

=head1 DESCRIPTION

We find all sorts of excuses to avoid writing tests for our code. Often it
seems too hard to isolate the code we want to test from the objects it is
dependent on. Mocking frameworks are available to help us with this. But it
still takes too long to set up the mock objects before you can get on with
testing the actual code in question.

Test::Mocha offers a simpler and more intuitive approach. Rather than setting
up the expected interactions beforehand, you ask questions about interactions
after the execution. The mocks can be created in almost no time. Yet they are
ready to be used out-of-the-box by pretending to be any type you want them to
be and accepting any method call on them. Explicit stubbing is only required
when the dependent object is expected to return a response. After executing
the code under test, you can selectively verify the interactions that you are
interested in. As you verify behaviour, you focus on external interfaces
rather than on internal state.

=cut

use Carp     qw( croak );
use Exporter qw( import );
use Test::Mocha::Inspect;
use Test::Mocha::Mock;
use Test::Mocha::Stub;
use Test::Mocha::Types 'NumRange', Mock => { -as => 'MockType' };
use Test::Mocha::Util qw( get_attribute_value );
use Test::Mocha::Verify;
use Types::Standard qw( Num );

our @EXPORT = qw(
    mock
    stub
    verify
    inspect
    clear
);

=func mock()

C<mock()> creates a new mock object.

    my $mock = mock;

By default, the mock object pretends to be anything you want it to be. Calling
C<isa()> or C<does()> on the object will always return true.

    ok( $mock->isa('AnyClass') );
    ok( $mock->does('AnyRole') );
    ok( $mock->DOES('AnyRole') );

It will also accept any method call on it. By default, any method call will
return C<undef> (in scalar context) or an empty list (in list context).

    ok( $mock->can('any_method') );
    is( $mock->any_method(@args), undef );

=cut

sub mock {
    return Test::Mocha::Mock->new if @_ == 0;

    my ($class) = @_;

    croak 'The argument for mock() must be a string'
        unless !ref $class;

    return Test::Mocha::Mock->new(class => $class);
}

=func stub($mock) -> method(@args) -> returns|dies|executes($response)

C<stub()> is used when you need a method to respond with something other than
returning C<undef>. You can specify 3 types of responses:

=begin :list

= C<returns(@values)>

Specifies that a stub should return 1 or more values.

    stub($mock)->method(@args)->returns(1, 2, 3);
    is_deeply( [ $mock->method(@args) ], [ 1, 2, 3 ] );

= C<dies($message)>

Specifies that a stub should raise an exception.

    stub($mock)->method(@args)->dies('exception');
    ok( exception { $mock->method(@args) } );

= C<executes(sub{...})>

Specifies that a stub should execute the given callback. The arguments used in
the method call are passed on to the callback.

    my @returns = qw( first second third );

    stub($list)->get(Int)->executes(sub {
        my ($i) = @_;
        die "index out of bounds" if $i < 0;
        return $returns[$i];
    });

    is( $list->get(0), 'first'  );
    is( $list->get(1), 'second' );
    is( $list->get(5), undef    );
    like( exception { $list->get(-1) }, qr/^index out of bounds/ ),

=end :list

A stub applies to the exact method and arguments specified. (But see also
L</"ARGUMENT MATCHING"> for a shortcut around this.)

    stub($list)->get(0)->returns('first');
    stub($list)->get(1)->returns('second');

    is( $list->get(0), 'first' );
    is( $list->get(1), 'second' );
    is( $list->get(2), undef );

You may chain responses together to provide a series of responses.

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

=cut

sub stub {
    my ($mock) = @_;

    croak 'stub() must be given a mock object'
        unless defined $mock && MockType->check($mock);

    return Test::Mocha::Stub->new(mock => $mock);
}

=func verify($mock, [%option], [$test_name]) -> method(@args)

C<verify()> is used to test the interactions with the mock object. You can use
it to verify that the correct methods were called, with the correct set of
arguments, and the correct number of times. C<verify()> plays nicely with
L<Test::Simple> and Co - it will print the test result along with your other
tests and calls to C<verify()> are counted in the test plan.

    verify($warehouse)->remove($item, 50);
    # prints: ok 1 - remove("book", 50) was called 1 time(s)

An option may be specified to constrain the test.

=begin :list

= C<times>

Specifies the number of times the given method is expected to be called. The
default is 1 if no other option is specified.

    verify( $mock, times => 3 )->method(@args)
    # print: ok 1 - method(@args) was called 3 time(s)

= C<at_least>

Specifies the minimum number of times the given method is expected to be
called.

    verify( $mock, at_least => 3 )->method(@args)
    # print: ok 1 - method(@args) was called at least 3 time(s)

= C<at_most>

Specifies the maximum number of times the given method is expected to be
called.

    verify( $mock, at_most => 5 )->method(@args)
    # print: ok 1 - method(@args) was called at most 5 time(s)

= C<between>

Specifies the minimum and maximum number of times the given method is expected
to be called.

    verify( $mock, between => [3, 5] )->method(@args)
    # prints: ok 1 - method(@args) was called between 3 and 5 time(s)

=end :list

An optional C<$test_name> may be specified to be printed instead of the
default.

    verify( $warehouse, 'inventory removed' )->remove_inventory($item, 50);
    # prints: ok 1 - inventory removed

    verify( $warehouse, times => 0, 'inventory not removed' )->remove_inventory($item, 50);
    # prints: ok 2 - inventory not removed

=cut

sub verify {
    my $mock = shift;
    my $test_name;
    $test_name = pop if (@_ % 2 == 1);
    my %options = @_;

    # set default option if none given
    $options{times} = 1 if keys %options == 0;

    croak 'verify() must be given a mock object'
        unless defined $mock && MockType->check($mock);

    croak 'You can set only one of these options: '
        . join ', ', map {"'$_'"} keys %options
        unless keys %options == 1;

    if (defined $options{times}) {
        croak "'times' option must be a number"
            unless Num->check( $options{times} );
    }
    elsif (defined $options{at_least}) {
        croak "'at_least' option must be a number"
            unless Num->check( $options{at_least} );
    }
    elsif (defined $options{at_most}) {
        croak "'at_most' option must be a number"
            unless Num->check( $options{at_most} );
    }
    elsif (defined $options{between}) {
        croak "'between' option must be an arrayref "
            . "with 2 numbers in ascending order"
            unless NumRange->check( $options{between} );
    }
    else {
        my ($option) = keys %options;
        croak "verify() was given an invalid option: '$option'";
    }

    # set test name if given
    $options{test_name} = $test_name if defined $test_name;

    return Test::Mocha::Verify->new(mock => $mock, %options);
}

=func inspect($mock) -> method(@args)

C<inspect()> returns a list of method calls matching the given method call
specification. It can be useful for debugging failed C<verify()> calls. It may
also be used in place of a complex C<verify()> call to break it down into
smaller tests.

    my @method_calls = inspect($warehouse)->remove_inventory(Str, Int);

Each method call object has a C<name> and an C<args> property, and it
is C<string> overloaded.

    is( $method_call->name, 'remove_inventory',       'method name' );
    is_deeply( [$method_call->args], ['book', 50],    'method args array' );
    is( $method_call, 'remove_inventory("book", 50)', 'method as string' );

=cut

sub inspect {
    my ($mock) = @_;

    croak 'inspect() must be given a mock object'
        unless defined $mock && MockType->check($mock);

    return Test::Mocha::Inspect->new(mock => $mock);
}

=func clear($mock)

Clears the method call history of the mock for it to be reused in another test.
Note that this does not affect the stubbed methods.

=cut

sub clear {
    my ($mock) = @_;

    croak 'clear() must be given a mock object'
        unless defined $mock && MockType->check($mock);

    my $calls = get_attribute_value($mock, 'calls');
    @$calls = ();

    return;
}

1;

=head1 ARGUMENT MATCHING

Argument matchers may be used with C<stub()>, C<verify()> or C<inspect>.
They are type constraints that are used to match method arguments. They save
you from having to specify the exact arguments. This is a powerful feature
that will save you time when writing your stubs and verifications.

=head2 Predefined types

You may use any L<Type::Tiny> type constraint such as those predefined in
L<Types::Standard>. (Moose type constraints such as L<MooseX::Types::Moose>
and L<MooseX::Types::Structured> will also work.)

    use Types::Standard qw( Any );

    my $mock = mock;
    stub($mock)->foo(Any)->returns('ok');

    print $mock->foo(1);        # prints: ok
    print $mock->foo('string'); # prints: ok

    verify($mock, times => 2)->foo(Defined);
    # prints: ok 1 - foo(Defined) was called 2 time(s)

You may use the normal features of type constraints: parameterized and
structured types, and type unions, intersections and negations (but there's no
need to use coercions).

    use Types::Standard qw( Any ArrayRef HashRef Int StrMatch );

    my $list = mock;
    $list->set(1, [1,2]);
    $list->set(0, 'foobar');

    # parameterized type
    # prints: ok 1 - set(Int, StrMatch[(?^:^foo)]) was called 1 time(s)
    verify($list)->set( Int, StrMatch[qr/^foo/] );

=head2 Self-defined types

You may also use your own type constraints, defined using L<Type::Utils>.

    use Type::Utils -all;

    # naming the type means it will be printed nicely in the verify() output
    my $positive_int = declare 'PositiveInt', as Int, where { $_ > 0 };

    # prints: ok 2 - set(PositiveInt, Any) was called 1 time(s)
    verify($list)->set( $positive_int, Any );

=head2 Argument slurping

You may use the L<C<slurpy()>|Types::Standard/Structured> function if you
don't care what are arguments are used. They will just slurp up the remaining
arguments as though they match. Note that empty argument lists are also
recognised by slurpy types.

    # prints: ok 3 - set({ slurpy: ArrayRef }) was called 2 time(s)
    verify($list)->set( slurpy ArrayRef );

    # prints: ok 4 - set({ slurpy: HashRef }) was called 2 time(s)
    verify($list)->set( slurpy HashRef );

=head1 TO DO

=for :list
* Enhanced verifications
* Module functions and class methods

=head1 ACKNOWLEDGEMENTS

This module is a fork from L<Test::Magpie> originally written by Oliver
Charles (CYCLES).

It is inspired by the popular L<Mockito|http://code.google.com/p/mockito/> for
Java and Python by Szczepan Faber.

=head1 SEE ALSO

L<Test::MockObject>

=cut
