#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';
use TestClass;

use ok 'Test::Mocha';

my $spy = spy( TestClass->new );

ok( $spy->isa('TestClass'), 'isa() called' );
is( ( inspect { $spy->isa('TestClass') } )[0],
    'isa("TestClass")', '... and inspected' );
called_ok { $spy->isa('TestClass') } '... and verified';

ok( $spy->DOES('TestClass'), 'DOES() called' );
is( ( inspect { $spy->DOES('TestClass') } )[0],
    'DOES("TestClass")', '... and inspected' );
called_ok { $spy->DOES('TestClass') } '... and verified';

ok( $spy->can('get'), 'can() called' );
is( ( inspect { $spy->can('get') } )[0], 'can("get")', '... and inspected' );
called_ok { $spy->can('get') } '... and verified';

my $nr_calls = 1;
is( $spy->ref, 'TestClass', 'ref() called as a method' );
is( ( inspect { $spy->ref } )[0], 'ref()', '... and inspected' );
SKIP: {
    skip 'UNIVERSAL::ref not compatible with Perl version >= 5.025', 3
        if $] ge '5.025';

    $nr_calls++;
    is( ref($spy), 'TestClass', '... or called as a function (via UNIVERSAL::ref)' );
    my $call = ( inspect { ref($spy) } )[-1];
    is( $call, 'ref()', '... and inspected' );
    # Ensure UNIVERSAL::ref is not recorded as caller when it intercepts the call
    is( ( $call->caller )[0], __FILE__, '... and caller is not UNIVERSAL::ref' );
}
called_ok { $spy->ref } &times($nr_calls), '... and verified';

done_testing;
