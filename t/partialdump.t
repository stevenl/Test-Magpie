#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 20;

use constant CLASS => 'Test::Mocha::PartialDump';

BEGIN { use_ok CLASS }

our $d = new_ok CLASS;

is( $d->dump("foo"), '"foo"', "simple value" );

is( $d->dump(undef), "undef", "undef" );

is( $d->dump("foo" => "bar"), 'foo: "bar"', "named params" );

is( $d->dump( \"foo" => "bar" ), '\\"foo", "bar"', "not named pairs" );

is( $d->dump( foo => "bar", gorch => [ 1, "bah" ] ),
    'foo: "bar", gorch: [ 1, "bah" ]', "recursion" );

is( $d->dump("foo\nbar"), '"foo\nbar"', "newline" );

is( $d->dump("foo" . chr(1)), '"foo\x{1}"', "non printable" );

my $foo = "foo";
is( $d->dump(\substr($foo, 0)), '\\"foo"', "reference to lvalue");

is( $d->dump(\\"foo"), '\\\\"foo"', "reference to reference" );

subtest 'max_length' => sub {
    my @list = 1 .. 10;
    local $d = CLASS->new(
        pairs        => 0,
        max_elements => undef,
        max_length   => undef,
    );

    is( $d->dump(@list), '1, 2, 3, 4, 5, 6, 7, 8, 9, 10', 'undefined');

    $d->{max_length} = 100;
    is( $d->dump(@list), '1, 2, 3, 4, 5, 6, 7, 8, 9, 10', 'high');

    $d->{max_length} = 10;
    is( $d->dump(@list), '1, 2, 3...', 'low' );

    $d->{max_length} = 0;
    is( $d->dump(@list), '...', 'zero' );
};

subtest 'max_elements for list' => sub {
    my @list = 1 .. 10;
    local $d = CLASS->new( pairs => 0 );

    $d->{max_elements} = undef;
    is( $d->dump(@list), '1, 2, 3, 4, 5, 6, 7, 8, 9, 10', 'undefined' );

    $d->{max_elements} = 100;
    is( $d->dump(@list), '1, 2, 3, 4, 5, 6, 7, 8, 9, 10', 'high' );

    $d->{max_elements} = 6;
    is( $d->dump(@list), '1, 2, 3, 4, 5, 6, ...', 'low' );

    $d->{max_elements} = 0;
    is( $d->dump(@list), '...', 'zero' );
};

subtest 'max_elements for pairs' => sub {
    my @list = 1 .. 10;
    local $d = CLASS->new( pairs => 1 );

    $d->{max_elements} = undef;
    is( $d->dump(@list), '1: 2, 3: 4, 5: 6, 7: 8, 9: 10', 'undefined' );

    $d->{max_elements} = 100;
    is( $d->dump(@list), '1: 2, 3: 4, 5: 6, 7: 8, 9: 10', 'high' );

    $d->{max_elements} = 3;
    is( $d->dump(@list), '1: 2, 3: 4, 5: 6, ...', 'low' );

    $d->{max_elements} = 0;
    is( $d->dump(@list), '...', 'zero' );
};

subtest 'max_depth' => sub {
    local $d = CLASS->new( max_depth => 10 );

    is( $d->dump( [ { foo => ["bar"] } ] ),
        '[ { foo: [ "bar" ] } ]', 'high' );

    $d->{max_depth} = 2;
    like( $d->dump( [ { foo => ["bar"] } ] ),
        qr/^\[ \{ foo: ARRAY\(0x[a-z0-9]+\) \} \]$/, 'low' );

    $d->{max_depth} = 0;
    like( $d->dump( [ { foo => ["bar"] } ] ),
        qr/^ARRAY\(0x[a-z0-9]+\)$/, 'zero' );
};

{
    local $d = CLASS->new( pairs => 0, list_delim => ',' );
    is( $d->dump("foo", "bar"), '"foo","bar"', "list_delim" );
}

{
    local $d = CLASS->new( pairs => 1, pair_delim => '=>' );
    is( $d->dump("foo" => "bar"), 'foo=>"bar"', "pair_delim" );
}

# ----------------------
# objects

package My::Object::Hash;
{
    use overload '""' => \&stringify;

    sub new {
        my ($class, $value) = @_;
        bless { value => $value }, $class;
    }
    sub stringify { $_[0]->{value} }
}

package My::Object::Array;
{
    use overload '""' => \&stringify;

    sub new {
        my ($class, $value) = @_;
        bless [ $value ], $class;
    }
    sub stringify { $_[0]->[0] }
}

package My::Object::Scalar;
{
    use overload '""' => \&stringify;

    sub new {
        my ($class, $value) = @_;
        bless \$value, $class;
    }
    sub stringify { ${$_[0]} }
}

package main;

my $hash   = My::Object::Hash->new('foo');
my $array  = My::Object::Array->new('foo');
my $scalar = My::Object::Scalar->new('foo');

subtest 'objects - dump' => sub {
    local $d = CLASS->new( objects => 1, stringify => 0 );

    is( $d->dump($hash), 'My::Object::Hash={ value: "foo" }' );
    is( $d->dump($array), 'My::Object::Array=[ "foo" ]' );
    is( $d->dump($scalar), 'My::Object::Scalar=\"foo"' );
};

subtest 'objects - string value' => sub {
    local $d = CLASS->new( objects => 0, stringify => 0 );

    like( $d->dump($hash), qr/^My::Object::Hash=HASH\(0x[a-z0-9]+\)$/ );
    like( $d->dump($array), qr/^My::Object::Array=ARRAY\(0x[a-z0-9]+\)$/ );
    like( $d->dump($scalar), qr/^My::Object::Scalar=SCALAR\(0x[a-z0-9]+\)$/ );
};

subtest 'objects - string overload' => sub {
    local $d = CLASS->new( objects => 0, stringify => 1 );

    is( $d->dump($hash), 'foo' );
    is( $d->dump($array), 'foo' );
    is( $d->dump($scalar), 'foo' );
};
