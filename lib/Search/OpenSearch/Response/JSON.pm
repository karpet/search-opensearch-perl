package Search::OpenSearch::Response::JSON;
use strict;
use warnings;
use Carp;
use base qw( Search::OpenSearch::Response );
use JSON;

sub stringify {
    my $self    = shift;
    my $results = $self->fetch_results();

    # TODO more.

    return encode_json($results);
}

1;
