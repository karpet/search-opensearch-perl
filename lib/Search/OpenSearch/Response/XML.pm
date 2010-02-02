package Search::OpenSearch::Response::XML;
use strict;
use warnings;
use Carp;
use base qw( Search::OpenSearch::Response );
use Data::Dump qw( dump );
use XML::Atom::Feed;
use XML::Atom::Entry;
use XML::Atom::Ext::OpenSearch;
use URI::Encode qw( uri_encode );
use POSIX qw( strftime );

sub stringify {
    my $self  = shift;
    my $pager = $self->fetch_pager();

    my @entries = $self->_build_entries;

    my $now = strftime '%Y-%m-%dT%H:%M:%SZ', gmtime;

    my $feed = XML::Atom::Feed->new;
    $feed->title( $self->title );
    $feed->author( $self->author );
    $feed->totalResults( $self->total );
    $feed->startIndex( $self->offset );
    $feed->itemsPerPage( $self->page_size );

    my $query = XML::Atom::Ext::OpenSearch::Query->new;
    $query->role('request');
    $query->totalResults( $self->total );
    $query->searchTerms( $self->query );
    $query->startIndex( $self->offset );

    # TODO language, et al
    $feed->add_Query($query);

    #$feed->id();# TODO generate uuid? cache per query?

    # main link
    my $link = XML::Atom::Link->new;
    $link->href( $self->link );
    $feed->add_link($link);

    # pager links
    my @pager_links;
    my $query_encoded = uri_encode( $self->query );
    my $this_uri
        = $self->link . '?q=' . $query_encoded . '&p=' . $self->page_size;

    my $self_link = XML::Atom::Link->new;
    $self_link->rel('self');
    $self_link->href( $this_uri . '&o=' . $self->offset );
    push @pager_links, $self_link;

    unless ( $pager->current_page == $pager->first_page ) {
        my $prev_link = XML::Atom::Link->new;
        $prev_link->rel('previous');
        $prev_link->href(
            $this_uri . '&o=' . ( $self->offset - $self->page_size ) );
        push @pager_links, $prev_link;
        my $first_link = XML::Atom::Link->new;
        $first_link->rel('first');
        $first_link->href( $this_uri . '&o=0' );
        push @pager_links, $first_link;
    }
    unless ( $pager->current_page == $pager->last_page ) {
        my $next_link = XML::Atom::Link->new;
        $next_link->rel('next');
        $next_link->href(
            $this_uri . '&o=' . ( $self->offset + $self->page_size ) );
        push @pager_links, $next_link;
        my $last_page = XML::Atom::Link->new;
        $last_page->rel('last');
        $last_page->href( $this_uri . '&o='
                . ( $self->page_size * ( $pager->last_page - 1 ) ) );
        push @pager_links, $last_page;
    }

    # add to feed
    for (@pager_links) {
        $feed->add_link($_);
    }

    # results
    for my $entry (@entries) {
        $feed->add_entry($entry);
    }

    return $feed->as_xml;
}

sub _build_entries {
    my $self    = shift;
    my $results = $self->fetch_results();
    my @entries;
    for my $result (@$results) {
        my $entry = XML::Atom::Entry->new;
        $entry->title( $result->{title} );
        $entry->content( $result->{summary} );
        $entry->id( $result->{uri} );
        my $link = XML::Atom::Link->new;
        $link->href( $result->{uri} );
        $entry->add_link($link);
        push @entries, $entry,;
    }
    return @entries;
}

1;

__END__

=head1 NAME

Search::OpenSearch::Response::XML - provide search results in XML format

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

Search::OpenSearch::Response::XML serializes to XML following
the OpenSearch specification at 
http://www.opensearch.org/Specifications/OpenSearch/1.1.

=head1 METHODS

This class is a subclass of Search::OpenSearch::Response. 
Only new or overridden methods are documented here.

=head2 stringify

Returns the Response in XML format.

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
