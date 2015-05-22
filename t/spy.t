##!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 13;
use Test::Fatal;
#use Scalar::Util qw( blessed );

use lib 't/lib';
use TestClass;

BEGIN { use_ok 'Test::Mocha' }

my $FILE = __FILE__;

# ----------------------
# creating a spy

my $obj = TestClass->new;
my $spy = spy($obj);
ok( $spy, 'spy($obj) creates a simple spy' );
is( $spy->__object, $obj, 'spy wraps object' );

# ----------------------
# spy acts as a wrapper to the real object

ok( $spy->isa('TestClass'),  'spy isa(TestClass)' );
ok( $spy->does('TestClass'), 'spy does(TestClass)' );
ok( $spy->DOES('TestClass'), 'spy DOES(TestClass)' );

#is( ref($spy), 'TestClass',  'ref(spy)' );
#is( $obj->ref, 'TestClass' );
#is( blessed($spy), 'TestClass' );
#is( $obj->ref, 'TestClass' );
#is( blessed($obj), 'TestClass' );

ok( !$spy->isa('Foo'),  'spy does not isa(Anything)' );
ok( !$spy->does('Bar'), 'spy does not does(Anything)' );
ok( !$spy->DOES('Baz'), 'spy does not DOES(Anything)' );

# ----------------------
# spy delegates method calls to the real object

is( $spy->test_method( bar => 1 ),
    'bar', 'spy accepts methods that it can delegate' );

subtest 'spy can(test_method)' => sub {
    ok( my $coderef = $spy->can('test_method'), 'can() returns positively' );
    is( ref($coderef), 'CODE', '... and return value is a coderef' );
    is( $coderef->( $spy, 5 ),
        5, '... and coderef delegates method call by default' );
    my $line = __LINE__ - 2;
    is(
        $spy->__calls->[-1]->stringify_long,
        qq{test_method(5) called at $FILE line $line},
        '... and method call is recorded'
    );
};

subtest 'spy does not can(any_method)' => sub {
    is( $spy->can('foo'), undef, 'can() returns undef' );
    my $line = __LINE__ - 1;
    is(
        $spy->__calls->[-1]->stringify_long,
        qq{can("foo") called at $FILE line $line},
        '... and method call is recorded'
    );
};

$spy->DESTROY;
isnt( $spy->__calls->[-1]->stringify,
    'DESTROY()', 'DESTROY() is not AUTOLOADed' );
