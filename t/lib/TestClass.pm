package TestClass;

use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub echo {
    my ( $self, $value ) = @_;
    return $value;
}

sub get  { }
sub set  { }
sub next { }

sub once   { }
sub twice  { }
sub thrice { }

sub direct {
    my $self = shift;
    $self->indirect
}
sub indirect { 'indirect' }

1;
