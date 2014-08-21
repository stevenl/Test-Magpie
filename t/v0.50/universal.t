#!/usr/bin/perl -T

use strict;
use warnings;
no warnings 'deprecated';

use Test::More tests => 18;

BEGIN { use_ok 'Test::Mocha' }

use Test::Mocha::Util qw( getattr );

my $mock = mock;

ok( stub( sub { $mock->isa('Foo') } )->returns(0), 'isa() can be stubbed' );
ok( !$mock->isa('Foo'), '... and called' );
called_ok( sub { $mock->isa('Foo') }, '... and verified' );

ok( stub( sub { $mock->DOES('Bar') } )->returns(0), 'DOES() can be stubbed' );
ok( !$mock->DOES('Bar'), '... and called' );
called_ok( sub { $mock->DOES('Bar') }, '... and verified' );

ok( stub( sub { $mock->does('Baz') } )->returns(0), 'does() can be stubbed' );
ok( !$mock->does('Baz'), '... and called' );
called_ok( sub { $mock->does('Baz') }, '... and verified' );

ok( stub( sub { $mock->can('foo') } )->returns(undef), 'can() can be stubbed' );
ok( !$mock->can('foo'), '... and called' );
called_ok( sub { $mock->can('foo') }, '... and verified' );

ok( stub( sub { $mock->ref } )->returns('Foo'), 'ref() can be stubbed' );
is( $mock->ref, 'Foo', '... and called as a method' );
is( ref($mock), 'Foo', '... or as a function' );
called_ok( sub { $mock->ref }, times => 2, '... and verified' );

# Ensure UNIVERSAL::ref is not recorded as caller when it intercepts the call
my $calls = getattr( $mock, 'calls' );
is( ( $calls->[-1]->caller )[0],
    __FILE__, '... and caller is not UNIVERSAL::ref' );

