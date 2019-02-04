#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More 0.88;

use ok 'Test::Mocha';

my $mock = mock;

stub { $mock->isa('Foo') } returns 0;
is( $mock->__stubs->{isa}[0], 'isa("Foo")', 'isa() can be stubbed' );
ok( !$mock->isa('Foo'), '... and called' );
is( ( inspect { $mock->isa('Foo') } )[0], 'isa("Foo")', '... and inspected' );
called_ok { $mock->isa('Foo') } '... and verified';

stub { $mock->DOES('Bar') } returns 0;
is( $mock->__stubs->{DOES}[0], 'DOES("Bar")', 'DOES() can be stubbed' );
ok( !$mock->DOES('Bar'), '... and called' );
is( ( inspect { $mock->DOES('Bar') } )[0], 'DOES("Bar")', '... and inspected' );
called_ok { $mock->DOES('Bar') } '... and verified';

stub { $mock->does('Baz') } returns 0;
is( $mock->__stubs->{does}[0], 'does("Baz")', 'does() can be stubbed' );
ok( !$mock->does('Baz'), '... and called' );
is( ( inspect { $mock->does('Baz') } )[0], 'does("Baz")', '... and inspected' );
called_ok { $mock->does('Baz') } '... and verified';

stub { $mock->can('foo') } returns undef;
is( $mock->__stubs->{can}[0], 'can("foo")', 'can() can be stubbed' );
ok( !$mock->can('foo'), '... and called' );
is( ( inspect { $mock->can('foo') } )[0], 'can("foo")', '... and inspected' );
called_ok { $mock->can('foo') } '... and verified';

my $nr_calls = 1;
stub { $mock->ref } returns 'Foo';
is( $mock->__stubs->{ref}[0], 'ref()', 'ref() can be stubbed' );
is( $mock->ref,               'Foo',   '... and called as a method' );
is( ( my $call = ( inspect { $mock->ref } )[0] ), 'ref()', '... and inspected' );
SKIP: {
    skip 'UNIVERSAL::ref not compatible with Perl version >= 5.025', 1
        if $] ge '5.025';

    $nr_calls++;
    is( ref($mock), 'Foo', '... or called as a function (via UNIVERSAL::ref)' );
    my $call = ( inspect { ref($mock) } )[-1];
    is( $call, 'ref()', '... and inspected' );
    # Ensure UNIVERSAL::ref is not recorded as caller when it intercepts the call
    is( ( $call->caller )[0], __FILE__, '... and caller is not UNIVERSAL::ref' );
}
called_ok { $mock->ref } &times($nr_calls), '... and verified';

done_testing;
