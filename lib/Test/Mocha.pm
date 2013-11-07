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
    stub( sub { $warehouse->has_inventory($item1, Int) } )->returns(1);

    # execute the code under test
    my $order = Order->new(item => $item1, quantity => 50);
    $order->fill($warehouse);

    # verify interactions with the dependent object
    ok( $order->is_filled, 'Order is filled' );
    called_ok(
        sub { $warehouse->remove_inventory($item1, 50) },
        '... and inventory is removed'
    );

    # clear the invocation history
    clear($warehouse);

=head1 DESCRIPTION

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

=cut

use Carp     qw( croak );
use Exporter qw( import );
use Test::Mocha::Inspect;
use Test::Mocha::Mock;
use Test::Mocha::Stub;
use Test::Mocha::Types 'NumRange', Mock => { -as => 'MockType' };
use Test::Mocha::Util qw( getattr get_method_call is_called );
use Test::Mocha::Verify;
use Types::Standard qw( ArrayRef HashRef Num slurpy );

our @EXPORT = qw(
    mock
    stub
    called_ok
    verify
    inspect
    inspect_all
    clear
    SlurpyArray
    SlurpyHash
);

=for Pod::Coverage SlurpyArray SlurpyHash
=cut

use constant {
    SlurpyArray => slurpy(ArrayRef),
    SlurpyHash  => slurpy(HashRef),
};

=func mock

    my $mock = mock;

C<mock()> creates a new mock object. It's that quick and simple!

The mock object is ready, as-is, to pretend to be anything you want it to be.
Calling C<isa()> or C<does()> on the object will always return true. This
is particularly handy when dependent objects are required to satisfy type
constraint checks with OO frameworks such as L<Moose>.

    ok( $mock->isa('AnyClass') );
    ok( $mock->does('AnyRole') );
    ok( $mock->DOES('AnyRole') );

It will also accept any method call on it. By default, method calls will
return C<undef> (in scalar context) or an empty list (in list context).

    ok( $mock->can('any_method') );
    is( $mock->any_method(@args), undef );

You can stub C<ref()> to specify the value it should return (see below for
more info about stubbing).

    stub( sub{ $mock->ref } )->returns('AnyClass');
    is( $mock->ref, 'AnyClass' );
    is( ref($mock), 'AnyClass' );

=cut

sub mock {
    return Test::Mocha::Mock->new(@_);
}

=func stub

    stub( sub { $mock->method(@args) } )->returns|throws|executes($response)

By default, the mock object already acts as a stub that accepts any method
call and returns C<undef>. However, you can use C<stub()> to tell a method to
give an alternative response. You can specify 3 types of responses:

=begin :list

= C<returns(@values)>

Specifies that a stub should return 1 or more values.

    stub( sub { $mock->method(@args) } )->returns(1, 2, 3);
    is_deeply( [ $mock->method(@args) ], [ 1, 2, 3 ] );

= C<throws($message)>

Specifies that a stub should raise an exception.

    stub( sub { $mock->method(@args) } )->throws('exception');
    ok( exception { $mock->method(@args) } );

= C<executes($coderef)>

Specifies that a stub should execute the given callback. The arguments used
in the method call are passed on to the callback.

    my @returns = qw( first second third );

    stub( sub { $list->get(Int) } )->executes(sub {
        my ( $self, $i ) = @_;
        die "index out of bounds" if $i < 0;
        return $returns[$i];
    });

    is( $list->get(0), 'first'  );
    is( $list->get(1), 'second' );
    is( $list->get(5), undef    );
    like( exception { $list->get(-1) }, qr/^index out of bounds/ ),

=end :list

A stub applies to the exact method and arguments specified (but see also
L</"ARGUMENT MATCHING"> for a shortcut around this).

    stub( sub { $list->get(0) } )->returns('first');
    stub( sub { $list->get(1) } )->returns('second');

    is( $list->get(0), 'first'  );
    is( $list->get(1), 'second' );
    is( $list->get(2),  undef   );

Chain responses together to provide a consecutive series.

    stub( sub { $iterator->next } )
        ->returns(1)
        ->returns(2)
        ->returns(3)
        ->throws('exhuasted');

    ok( $iterator->next == 1 );
    ok( $iterator->next == 2 );
    ok( $iterator->next == 3 );
    ok( exception { $iterator->next } );

The last stubbed response will persist until it is overridden.

    stub( sub { $warehouse->has_inventory($item, 10) } )->returns(1);
    ok( $warehouse->has_inventory($item, 10) ) for 1 .. 5;

    stub( sub { $warehouse->has_inventory($item, 10) } )->returns(0);
    ok( !$warehouse->has_inventory($item, 10) ) for 1 .. 5;

=cut

sub stub {
    my ( $arg ) = @_;

    if ( defined $arg ) {
        if ( ref($arg) eq 'CODE' ) {
            $Test::Mocha::Mock::num_method_calls = 0;
            my $method_call = get_method_call($arg);
            my $stubs = getattr( $method_call->invocant, 'stubs' );
            unshift @{ $stubs->{ $method_call->name } }, $method_call;

            return Test::Mocha::MethodStub->cast( $method_call );
        }
        elsif ( MockType->check($arg) ) {
            warnings::warnif( 'deprecated', 'stub() interface has changed' );
            return Test::Mocha::Stub->new( mock => $arg );
        }
    }
    croak 'stub() must be given a coderef';
}

=func called_ok

    called_ok( sub { $mock->method(@args) }, [%option], [$test_name] )

C<called_ok()> is used to test the interactions with the mock object. You can
use it to verify that the correct method was called, with the correct set of
arguments, and the correct number of times. C<called_ok()> plays nicely with
L<Test::Simple> and Co - it will print the test result along with your other
tests and you must count calls to C<called_ok()> in your test plans.

    called_ok( sub { $warehouse->remove($item, 50) } );
    # prints: ok 1 - remove("book", 50) was called 1 time(s)

An option may be specified to constrain the test.

=begin :list

= C<times>

Specifies the number of times the given method is expected to be called.
The default is 1 if no other option is specified.

    called_ok( sub { $mock->method(@args) }, times => 3 )
    # prints: ok 1 - method(@args) was called 3 time(s)

= C<at_least>

Specifies the minimum number of times the given method is expected to be
called.

    called_ok( sub { $mock->method(@args) }, at_least => 3 )
    # prints: ok 1 - method(@args) was called at least 3 time(s)

= C<at_most>

Specifies the maximum number of times the given method is expected to be
called.

    called_ok( sub { $mock->method(@args) }, at_most => 5 )
    # prints: ok 1 - method(@args) was called at most 5 time(s)

= C<between>

Specifies the minimum and maximum number of times the given method is
expected to be called.

    called_ok( sub { $mock->method(@args) }, between => [3, 5] )
    # prints: ok 1 - method(@args) was called between 3 and 5 time(s)

=end :list

An optional C<$test_name> may be specified to be printed instead of the
default.

    called_ok(
        sub { $warehouse->remove_inventory($item, 50) },
        'inventory removed'
    );
    # prints: ok 1 - inventory removed

    called_ok(
        sub { $warehouse->remove_inventory($item, 50) },
        times => 0,
        'inventory not removed'
    );
    # prints: ok 2 - inventory not removed

=cut

sub called_ok {
    my ( $coderef, %options ) = _get_called_ok_args(@_);

    croak 'called_ok() must be given a coderef'
        unless defined($coderef) && ref($coderef) eq 'CODE';

    $Test::Mocha::Mock::num_method_calls = 0;
    is_called( get_method_call($coderef), %options );
    return;
}

# verify() has been retained for backwards compatibility only
=for Pod::Coverage verify
=cut

sub verify {
    my ( $mock, %options ) = _get_called_ok_args(@_);

    warnings::warnif(
        'deprecated',
        'verify() is deprecated; use called_ok() instead'
    );
    croak 'verify() must be given a mock object'
        unless defined($mock) && MockType->check($mock);

    return Test::Mocha::Verify->new( mock => $mock, %options );
}

sub _get_called_ok_args {
    my $coderef = shift;
    my $test_name;
    $test_name = pop if (@_ % 2 == 1);
    my %options = @_;

    # set default option if none given
    $options{times} = 1 if keys %options == 0;

    croak 'You can set only one of these options: '
        . join ', ', map { "'$_'" } keys %options
        unless keys %options == 1;

    if ( defined $options{times} ) {
        croak "'times' option must be a number"
            unless Num->check( $options{times} );
    }
    elsif ( defined $options{at_least} ) {
        croak "'at_least' option must be a number"
            unless Num->check( $options{at_least} );
    }
    elsif ( defined $options{at_most} ) {
        croak "'at_most' option must be a number"
            unless Num->check( $options{at_most} );
    }
    elsif ( defined $options{between} ) {
        croak "'between' option must be an arrayref "
            . "with 2 numbers in ascending order"
            unless NumRange->check( $options{between} );
    }
    else {
        my ( $option ) = keys %options;
        croak "called_ok() was given an invalid option: '$option'";
    }
    $options{ test_name } = $test_name if defined $test_name;

    return ( $coderef, %options );
}

=func inspect

    @method_calls = inspect( sub { $mock->method(@args) } )

    ( $method_call ) = inspect( sub { $warehouse->remove_inventory(Str, Int) } );

    is( $method_call->name,            'remove_inventory' );
    is_deeply( [$method_call->args],   ['book', 50] );
    is_deeply( [$method_call->caller], ['test.pl', 5] );
    is( "$method_call", 'remove_inventory("book", 50) called at test.pl line 5' );

C<inspect()> returns a list of method calls matching the given method call
specification. It can be useful for debugging failed C<called_ok()> calls.
Or use it in place of a complex C<called_ok()> call to break it down into
smaller tests.

The method call objects have the following accessor methods:

=for :list
* C<name> - The name of the method called.
* C<args> - The list of arguments passed to the method call.
* C<caller> - The file and line number from which the method was called.

They are also C<string> overloaded.

=cut

sub inspect {
    my ( $arg ) = @_;

    if ( defined $arg ) {
        if ( ref($arg) eq 'CODE' ) {
            $Test::Mocha::Mock::num_method_calls = 0;
            my $method_call = get_method_call($arg);
            my $mock        = $method_call->invocant;
            my $calls       = getattr( $mock, 'calls' );
            return grep { $method_call->satisfied_by($_) } @$calls;
        }
        elsif ( MockType->check($arg) ) {
            warnings::warnif( 'deprecated', 'inspect() interface has changed' );
            return Test::Mocha::Stub->new( mock => $arg );
        }
    }
    croak 'inspect() must be given a coderef';
}

=func inspect_all

    @all_method_calls = inspect_all($mock)

C<inspect_all()> returns a list containing all methods called on the mock
object. This is mainly used for debugging.

=cut

sub inspect_all {
    my ( $mock ) = @_;

    croak 'inspect_all() must be given a mock object'
        unless defined $mock && MockType->check($mock);

    return @{ $mock->{calls} };
}

=func clear

    clear(@mocks)

Clears the method call history for one or more mocks so that they can be
reused in another test. Note that this does not affect the stubbed methods.

=cut

sub clear {
    my @mocks = @_;

    croak 'clear() must be given one or more mock objects'
        if !@mocks || grep { ! MockType->check($_) } @mocks;

    @{ getattr( $_, 'calls' ) } = ( ) foreach @mocks;

    return;
}

1;

=head1 ARGUMENT MATCHING

Argument matchers may be used in place of specifying exact method arguments.
They allow you to be more general and will save you much time in your
method specifications to stubs and verifications. Argument matchers may be used
with C<stub()>, C<called_ok()> and C<inspect>.

=head2 Pre-defined types

You may use any of the ready-made types in L<Types::Standard>. (Alternatively,
Moose types like those in L<MooseX::Types::Moose> and
L<MooseX::Types::Structured> will also work.)

    use Types::Standard qw( Any );

    my $mock = mock;
    stub( sub { $mock->foo(Any) } )->returns('ok');

    print $mock->foo(1);        # prints: ok
    print $mock->foo('string'); # prints: ok

    called_ok( sub { $mock->foo(Defined) }, times => 2 );
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
    called_ok( sub { $list->set( Int, StrMatch[qr/^foo/] ) } );

=head2 Self-defined types

You may also use your own types, defined using L<Type::Utils>.

    use Type::Utils -all;

    # naming the type means it will be printed nicely in called_ok()'s output
    my $positive_int = declare 'PositiveInt', as Int, where { $_ > 0 };

    # prints: ok 2 - set(PositiveInt, Any) was called 1 time(s)
    called_ok( sub { $list->set($positive_int, Any) } );

=head2 Argument slurping

C<SlurpyArray> and C<SlurpyHash> are special argument matchers exported by
Test::Mocha that you can use when you don't care what arguments are used.
They will just slurp up the remaining arguments as though they match.

    called_ok( sub { $list->set(SlurpyArray) } );
    called_ok( sub { $list->set(Int, SlurpyHash) } );

Because they consume the remaining arguments, you can't use further argument
validators after them. But you can, of course, use them before. Note also that
they will match empty argument lists.

=head1 TO DO

=for :list
* Enhanced verifications
* Module functions and class methods

=head1 ACKNOWLEDGEMENTS

This module is a fork from L<Test::Magpie> originally written by Oliver
Charles (CYCLES).

It is inspired by the popular L<Mockito|http://code.google.com/p/mockito/>
for Java and Python by Szczepan Faber.

=head1 SEE ALSO

L<Test::MockObject>

=cut
