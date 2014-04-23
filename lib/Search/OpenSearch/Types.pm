package Search::OpenSearch::Types;
use Type::Tiny;
use Types::Standard qw( InstanceOf Maybe Object Bool );
use Type::Utils qw( declare as where inline_as coerce from );

# singleton types
my $FACETS = declare as Object;
coerce $FACETS, from HashRef, q{ Search::OpenSearch::Facets->new($_) };

sub facets { return $FACETS }

1;
