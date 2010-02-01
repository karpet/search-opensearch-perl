package Search::OpenSearch::Response;
use strict;
use warnings;
use base qw( Rose::ObjectX::CAF );
use Carp;
use overload
    '""'     => sub { $_[0]->stringify; },
    'bool'   => sub {1},
    fallback => 1;

__PACKAGE__->mk_accessors(qw( results total offset page_size fields facets ));

sub stringify { croak "$_[0] does not implement stringify()" }

sub fetch_results {
    my $self    = shift;
    my $fields  = shift || [];
    my $results = $self->results or croak "no results defined";
    my @results;
    while ( my $result = $results->next ) {
        my %res = (
            score   => $result->score,
            uri     => $result->uri,
            mtime   => $result->mtime,
            title   => $result->title,
            summary => $result->summary,
        );
        for my $field (@$fields) {
            $res{$field} = $result->get_property($field);
        }
        push @results, \%res;
    }
    return \@results;
}

sub fetch_facets {
    my $self = shift;
    my $facet_names = shift or croak "facet_names required";
    croak "TODO";

}

1;
