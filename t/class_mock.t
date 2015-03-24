#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 9;
use Test::Fatal;
use Test::Builder::Tester;
use Types::Standard qw( Any slurpy );

BEGIN { use_ok 'Test::Mocha' }

use Test::Mocha::Util qw( getattr );
use Types::Standard qw( Any Int slurpy );

# setup
my $file  = __FILE__;
my $mock  = class_mock 'Some::Class';
my $stubs = getattr( $mock, 'stubs' );
my $e;

# Class method - stubs
test_out('ok 1');
stub { Some::Class->class_method(1) } returns "foo";
is( Some::Class->class_method(1), "foo" );
test_test("class_mock stubs class method");

# Class method - called_ok
test_out('ok 1 - Some::Class->class_method(1) was called 1 time(s)');
called_ok { Some::Class->class_method(1) };
test_test('called_ok with class method');

# Module function - stubs
test_out('ok 1');
stub { Some::Class::module_function(1) } returns "foo";
is( Some::Class::module_function(1), "foo" );
test_test("class_mock stubs module function");

# Module function - called_ok
test_out('ok 1 - Some::Class::module_function(1) was called 1 time(s)');
called_ok { Some::Class::module_function(1) };
test_test('called_ok with module function');

# Executes - class method
test_out('ok 1');
stub { Some::Class->class_method( 2, 3 ) }
executes { my $self = shift; return join( ",", @_ ) };
is( Some::Class->class_method( 2, 3 ), "2,3" );
test_test("class method executes alternate method");

# Executes - module function method
test_out('ok 1');
stub { Some::Class::module_function( 2, 3 ) }
executes { my $self = shift; return join( ",", @_ ) };
is( Some::Class::module_function( 2, 3 ), "2,3" );
test_test("module function executes alternate method");

# Throws - class method
test_out('ok 1');
stub { Some::Class->class_method(4) } throws 'My::Exception';
$e = exception { Some::Class->class_method(4) };
like( $e, qr/My::Exception/ );
test_test("class method throws exception");

# Throws - module function
test_out('ok 1');
stub { Some::Class::module_function(4) } throws 'My::Exception';
$e = exception { Some::Class::module_function(4) };
like( $e, qr/My::Exception/ );
test_test("module function throws exception");
