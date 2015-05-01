package Test::Mocha::Stub;
# ABSTRACT: Mock wrapper to create method stubs

use strict;
use warnings;

use Carp qw( croak );
use Test::Mocha::MethodStub;
use Test::Mocha::Types qw( Mock Slurpy );
use Test::Mocha::Util qw( extract_method_name has_caller_package );
use Types::Standard qw( ArrayRef HashRef );

our $AUTOLOAD;

sub new {
    # uncoverable pod
    my ( $class, %args ) = @_;
    ### assert: defined $args{mock} && Mock->check( $args{mock} )
    return bless \%args, $class;
}

sub __mock {
    my ($self) = @_;
    return $self->{mock};
}

sub AUTOLOAD {
    my ( $self, @args ) = @_;
    my $method_name = extract_method_name($AUTOLOAD);

    my $i = 0;
    my $seen_slurpy;
    foreach (@args) {
        if ( Slurpy->check($_) ) {
            $seen_slurpy = 1;
            last;
        }
        $i++;
    }
    croak 'No arguments allowed after a slurpy type constraint'
      if $i < $#args;

    if ($seen_slurpy) {
        my $slurpy = $args[$i]->{slurpy};
        croak 'Slurpy argument must be a type of ArrayRef or HashRef'
          unless $slurpy->is_a_type_of(ArrayRef)
          || $slurpy->is_a_type_of(HashRef);
    }

    my $stub = Test::Mocha::MethodStub->new(
        name => $method_name,
        args => \@args,
    );

    # add new stub to front of queue so that it takes precedence
    # over existing stubs that would satisfy the same invocations
    unshift @{ $self->__mock->__stubs->{$method_name} }, $stub;

    return $stub;
}

# Let AUTOLOAD() handle the UNIVERSAL methods

sub isa {
    # uncoverable pod
    $AUTOLOAD = 'isa';
    goto &AUTOLOAD;
}

sub DOES {
    # uncoverable pod
    $AUTOLOAD = 'DOES';
    goto &AUTOLOAD;
}

sub can {
    # uncoverable pod
    my ( $self, $method_name ) = @_;

    # Handle can('CARP_TRACE') for internal croak()'s (Carp v1.32+)
    return if has_caller_package(__PACKAGE__);

    $AUTOLOAD = 'can';
    goto &AUTOLOAD;
}

# Don't let AUTOLOAD() handle DESTROY() so that object can be destroyed
sub DESTROY { }

1;
