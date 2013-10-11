package Test::Mocha::MethodCall;
# ABSTRACT: Objects to represent method calls

use strict;
use warnings;

use Test::Mocha::Method;

our @ISA = qw( Test::Mocha::Method );

use overload '""' => \&stringify, fallback => 1;

sub new {
    # uncoverable pod
    my ($class, %args) = @_;
    # caller should be an arrayref tuple [file, line]
    ### assert: defined $args{caller}
    ### assert: ref $args{caller} eq 'ARRAY' && @{$args{caller}} == 2
    return $class->SUPER::new(%args);
}

sub caller {
    # uncoverable pod
    return @{ $_[0]->{caller} };
}

sub stringify {
    # uncoverable pod
    my ($self) = @_;
    return sprintf(
        '%s called at %s line %d',
        $self->SUPER::stringify,
        $self->caller,
    );
}

1;
