#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 3;

use constant CLASS => 'Test::Mocha::PartialDump';

BEGIN { use_ok CLASS }

my $d = CLASS->new( pairs => 0, list_delim => ',' );

is( $d->dump("foo", "bar"), '"foo","bar"', "list_delim" );

$d = CLASS->new( pairs => 1, pair_delim => '=>' );

is( $d->dump("foo" => "bar"), 'foo=>"bar"', "pair_delim" );
