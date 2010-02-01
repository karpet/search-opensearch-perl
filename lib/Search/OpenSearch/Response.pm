package Search::OpenSearch::Response;
use strict;
use warnings;
use base qw( Rose::ObjectX::CAF );
use Carp;
use overload
    '""'     => sub { $_[0]->stringify; },
    'bool'   => sub {1},
    fallback => 1;

__PACKAGE__->mk_accessors(
    qw(
        debug
        results
        total
        offset
        page_size
        fields
        facets
        query

        )
);

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

__END__

=head1 NAME

Search::OpenSearch::Response - provide search results in OpenSearch format

=head1 SYNOPSIS

 use Search::OpenSearch;
 my $engine = Search::OpenSearch->engine(
    type    => 'KSx',
    index   => [qw( path/to/index1 path/to/index2 )],
    facets  => {
        names       => [qw( color size flavor )],
        sample_size => 10_000,
    },
    fields  => [qw( color size flavor )],
 );
 my $response = $engine->search(
    q           => 'quick brown fox',   # query
    s           => 'rank desc',         # sort order
    o           => 0,                   # offset
    p           => 25,                  # page size
    h           => 1,                   # highlight query terms in results
    c           => 0,                   # return count stats only (no results)
    L           => 'field|low|high',    # limit results to inclusive range
    f           => 1,                   # include facets
    format      => 'XML',               # or JSON
 );
 print $response;

=head1 DESCRIPTION

Search::OpenSearch::Response is an abstract base class with some
common methods for all Response subclasses.

=head1 METHODS

This class is a subclass of Rose::ObjectX::CAF. Only new or overridden
methods are documented here.

The following standard get/set attribute methods are available:

=over

=item debug

=item results

An interator object behaving like SWISH::Prog::Results.

=item total

=item offset

=item page_size

=item fields

=item facets

=item query

=back

=head2 fetch_results

Returns arrayref of hashrefs representing the results().

=head2 fetch_facets

Returns arrayref of hashrefs representing the facets of results().

=head2 stringify

Returns the Response in the chosen serialization format.

Response objects are overloaded to call stringify().

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-opensearch at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-OpenSearch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::OpenSearch::Response


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-OpenSearch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-OpenSearch>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-OpenSearch/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
