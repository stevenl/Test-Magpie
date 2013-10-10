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
    ### assert: defined $args{caller_file}
    ### assert: defined $args{caller_line}
    return $class->SUPER::new(%args);
}

sub caller_file {
    # uncoverable pod
    return $_[0]->{caller_file};
}

sub caller_line {
    # uncoverable pod
    return $_[0]->{caller_line};
}

sub stringify {
    # uncoverable pod
    my ($self) = @_;
    return sprintf(
        '%s called at %s line %d',
        $self->SUPER::stringify,
        $self->caller_file,
        $self->caller_line,
    );
}

1;
