package Test::Mocha::PartialDump;
# ABSTRACT: Partial dumping of data structures, optimized for argument printing

# ===================================================================
# This code was copied and adapted from Devel::PartialDump 0.15.
#
#   Copyright (c) 2008, 2009 Yuval Kogman. All rights reserved
#   This program is free software; you can redistribute
#   it and/or modify it under the same terms as Perl itself.
#
# ===================================================================

use strict;
use warnings;

use Scalar::Util qw( looks_like_number reftype blessed );

sub new {
    # uncoverable pod
    my ( $class, %args ) = @_;

    # attribute defaults
    $args{ max_length   } = undef unless exists $args{ max_length   };
    $args{ max_elements } = 6     unless exists $args{ max_elements };
    $args{ max_depth    } = 2     unless exists $args{ max_depth    };
    $args{ stringify    } = 0     unless exists $args{ stringify    };
    $args{ pairs        } = 1     unless exists $args{ pairs        };
    $args{ objects      } = 1     unless exists $args{ objects      };
    $args{ list_delim   } = ', '  unless exists $args{ list_delim   };
    $args{ pair_delim   } = ': '  unless exists $args{ pair_delim   };

    return bless \%args, $class;
}

sub dump {
    # uncoverable pod
    my ( $self, @args ) = @_;

    my $method = "dump_as_"
        . ( $self->should_dump_as_pairs(@args) ? "pairs" : "list" );

    my $dump = $self->$method(1, @args);

    if ( defined $self->{max_length}
          and length($dump) > $self->{max_length}
    ) {
        my $max_length = $self->{max_length} - 3;
        $max_length = 0 if $max_length < 0;
        substr( $dump, $max_length, length($dump) - $max_length, '...' );
    }

    return $dump;
}

sub should_dump_as_pairs {
    # uncoverable pod
    my ( $self, @what ) = @_;

    return unless $self->{pairs};

    return if @what % 2 != 0; # must be an even list

    for ( my $i = 0; $i < @what; $i += 2 ) {
        return if ref $what[$i]; # plain strings are keys
    }

    return 1;
}

sub dump_as_pairs {
    # uncoverable pod
    my ( $self, $depth, @what ) = @_;

    my $truncated;
    if ( defined $self->{max_elements}
          and ( @what / 2 ) > $self->{max_elements}
    ) {
        $truncated = 1;
        @what = splice(@what, 0, $self->{max_elements} * 2 );
    }

    return join( $self->{list_delim},
        $self->_dump_as_pairs($depth, @what),
        ( $truncated ? "..." : () ),
    );
}

sub _dump_as_pairs {
    my ( $self, $depth, @what ) = @_;

    return unless @what;

    my ( $key, $value, @rest ) = @what;

    return (
        ( $self->format_key($depth, $key) . $self->{pair_delim}
          . $self->format($depth, $value) ),
        $self->_dump_as_pairs($depth, @rest),
    );
}

sub dump_as_list {
    # uncoverable pod
    my ( $self, $depth, @what ) = @_;

    my $truncated;
    if ( defined $self->{max_elements} and @what > $self->{max_elements} ) {
        $truncated = 1;
        @what = splice(@what, 0, $self->{max_elements} );
    }

    return join( $self->{list_delim},
        ( map { $self->format($depth, $_) } @what ),
        ( $truncated ? "..." : () ),
    );
}

sub format {
    # uncoverable pod
    my ( $self, $depth, $value ) = @_;

    defined($value)
        ? ( ref($value)
            ? ( blessed($value)
                ? $self->format_object($depth, $value)
                : $self->format_ref($depth, $value) )
            : ( looks_like_number($value)
                ? $self->format_number($depth, $value)
                : $self->format_string($depth, $value) ) )
        : $self->format_undef($depth, $value),
}

sub format_key {
    # uncoverable pod
    my ( $self, $depth, $key ) = @_;
    return $key;
}

sub format_ref {
    # uncoverable pod
    my ( $self, $depth, $ref ) = @_;

    if ( $depth > $self->{max_depth} ) {
        return overload::StrVal($ref);
    } else {
        my $reftype = reftype($ref);
           $reftype = 'SCALAR'
                if $reftype eq 'REF' || $reftype eq 'LVALUE';
        my $method = "format_" . lc $reftype;

        # uncoverable branch false
        if ( $self->can($method) ) {
            return $self->$method( $depth, $ref );
        } else {
            return overload::StrVal($ref); # uncoverable statement
        }
    }
}

sub format_array {
    # uncoverable pod
    my ( $self, $depth, $array ) = @_;

    my $class = blessed($array) || '';
    $class .= "=" if $class;

    return $class . "[ " . $self->dump_as_list($depth + 1, @$array) . " ]";
}

sub format_hash {
    # uncoverable pod
    my ( $self, $depth, $hash ) = @_;

    my $class = blessed($hash) || '';
    $class .= "=" if $class;

    return $class . "{ "
      . $self->dump_as_pairs(
            $depth + 1,
            map { $_ => $hash->{$_} } sort keys %$hash
        )
      . " }";
}

sub format_scalar {
    # uncoverable pod
    my ( $self, $depth, $scalar ) = @_;

    my $class = blessed($scalar) || '';
    $class .= "=" if $class;

    return $class . "\\" . $self->format($depth + 1, $$scalar);
}

sub format_object {
    # uncoverable pod
    my ( $self, $depth, $object ) = @_;

    if ( $self->{objects} ) {
        return $self->format_ref($depth, $object);
    } else {
        return $self->{stringify} ? "$object" : overload::StrVal($object);
    }
}

sub format_number {
    # uncoverable pod
    my ( $self, $depth, $value ) = @_;
    return "$value";
}

sub format_string {
    # uncoverable pod
    my ( $self, $depth, $str ) =@_;
    # FIXME use String::Escape ?

    # remove vertical whitespace
    $str =~ s/\n/\\n/g;
    $str =~ s/\r/\\r/g;

    # reformat nonprintables
    $str =~ s/(\P{IsPrint})/"\\x{" . sprintf("%x", ord($1)) . "}"/ge;

    qq{"$str"};
}

sub format_undef {
    # uncoverable pod
    "undef"
}

1;
