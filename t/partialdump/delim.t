#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 4;

use constant CLASS => 'Test::Mocha::PartialDump';

BEGIN { use_ok CLASS }

my $d = new_ok CLASS;

$d->{pairs} = 0;
$d->{list_delim} = ",";

is( $d->dump("foo", "bar"), '"foo","bar"', "list_delim" );

$d->{pairs} = 1;
$d->{pair_delim} = "=>";

is( $d->dump("foo" => "bar"), 'foo=>"bar"', "pair_delim" );
