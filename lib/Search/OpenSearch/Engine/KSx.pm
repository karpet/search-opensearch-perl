package Search::OpenSearch::Engine::KSx;
use strict;
use warnings;
use Carp;
use base qw( Search::OpenSearch::Engine );
use SWISH::Prog::KSx::Searcher;

sub init_searcher {
    my $self     = shift;
    my $index    = $self->index or croak "index not defined";
    my $searcher = SWISH::Prog::KSx::Searcher->new( invindex => $index );
    return $searcher;
}

1;
