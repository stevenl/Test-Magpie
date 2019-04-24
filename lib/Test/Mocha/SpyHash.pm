package Test::Mocha::SpyHash;
# tied hash support for spy

use strict;
use warnings;

use Tie::Hash ();

use parent -norequire, 'Tie::ExtraHash';

# pass spy attributes hashref. the tied hash will access the real object.
# access to the spy attributes is available through tied(%$spy)->[1].
sub TIEHASH
{
    my ($class, $args) = @_;
    return bless[$args->{object}, $args], $class;
}

1;
