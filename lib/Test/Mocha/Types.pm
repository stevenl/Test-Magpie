package Test::Mocha::Types;
# ABSTRACT: Type constraints used internally by Mocha

use Type::Library
    -base,
    -declare => qw(
        Matcher
        Mock
        NumRange
    );

use Type::Utils -all;
use Types::Standard qw( Num Tuple );

class_type Matcher, { class => 'Type::Tiny' };

class_type Mock, { class => 'Test::Mocha::Mock' };

declare NumRange, as Tuple[Num, Num], where { $_->[0] < $_->[1] };

1;
