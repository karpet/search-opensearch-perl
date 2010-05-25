package Search::OpenSearch::Engine;
use strict;
use warnings;
use Carp;
use base qw( Rose::ObjectX::CAF );
use Scalar::Util qw( blessed );
use Search::OpenSearch::Facets;
use Search::OpenSearch::Response::XML;
use Search::OpenSearch::Response::JSON;
use Search::Tools::XML;
use Search::Tools;
use CHI;
use Time::HiRes qw( time );

__PACKAGE__->mk_accessors(qw( index facets fields link cache cache_ttl ));

our $VERSION = '0.07';

use Rose::Object::MakeMethods::Generic (
    'scalar --get_set_init' => 'searcher', );

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    if ( $self->facets and !blessed( $self->facets ) ) {
        $self->facets(
            Search::OpenSearch::Facets->new( %{ $self->facets } ) );
    }
    $self->{cache} ||= CHI->new(
        driver           => 'File',
        dir_create_mode  => 0770,
        file_create_mode => 0660,
        root_dir         => "/tmp/opensearch_cache",
    );
    $self->{cache_ttl} = 60 * 60 * 1;    # 1 hour

    return $self;
}
sub init_searcher { croak "$_[0] does not implement init_searcher()" }
sub type          { croak "$_[0] does not implement type()" }

sub search {
    my $self  = shift;
    my %args  = @_;
    my $query = $args{'q'};
    if ( !defined $query ) { croak "query required"; }
    my $start_time      = time();
    my $offset          = $args{'o'} || 0;
    my $sort_by         = $args{'s'} || 'score DESC';
    my $page_size       = $args{'p'} || 25;
    my $apply_hilite    = $args{'h'} || 1;
    my $count_only      = $args{'c'} || 0;
    my $limits          = $args{'L'} || [];
    my $include_results = $args{'r'};
    $include_results = 1 unless defined $include_results;
    my $include_facets = $args{'f'};
    $include_facets = 1 unless defined $include_facets;

    my $format = uc( $args{format} || 'XML' );
    my $response_class = $args{response_class}
        || 'Search::OpenSearch::Response::' . $format;

    if ( !ref($limits) ) {
        $limits = [ split( m/,/, $limits ) ];
    }
    my @limits;
    for my $limit (@$limits) {
        my ( $field, $low, $high ) = split( m/\|/, $limit );
        my $range = $self->set_limit(
            field => $field,
            lower => $low,
            upper => $high,
        );
        push @limits, $range;
    }

    my $searcher = $self->searcher or croak "searcher not defined";
    my $results = $searcher->search(
        $query,
        {   start => $offset,
            max   => $page_size,
            limit => \@limits,
        }
    );
    my $search_time = sprintf( "%0.5f", time() - $start_time );
    my $start_build = time();
    my $response
        = $count_only
        ? $response_class->new( total => $results->hits )
        : $response_class->new(
        fields      => $self->fields,
        offset      => $offset,
        page_size   => $page_size,
        total       => $results->hits,
        query       => $query,
        link        => $self->link,
        search_time => $search_time,
        engine      => blessed($self),
        );
    if ($include_results) {
        $response->results(
            $self->build_results(
                fields    => $self->fields,
                results   => $results,
                page_size => $page_size,
                query     => $query
            )
        );
    }
    if ($include_facets) {
        $response->facets( $self->get_facets( $query, $results ) );
    }
    my $build_time = sprintf( "%0.5f", time() - $start_build );
    $response->build_time($build_time);
    return $response;
}

sub set_limit {
    my $self  = shift;
    my %args  = @_;
    my @range = ( $args{field}, $args{lower}, $args{upper} );
    return \@range;
}

sub get_facets {
    my $self      = shift;
    my $query     = shift;
    my $results   = shift;
    my $cache_key = ref($self) . $query;
    my $cache     = $self->cache or return;

    my $facets;
    if ( $cache->get($cache_key) ) {
        $facets = $cache->get($cache_key);
    }
    else {
        $facets = $self->build_facets( $query, $results );
        $cache->set( $cache_key, $facets, $self->cache_ttl );
    }
    return $facets;
}

sub build_facets {
    croak ref(shift) . " must implement build_facets()";
}

sub build_results {
    my $self      = shift;
    my %args      = @_;
    my $fields    = $args{fields} || $self->fields || [];
    my $results   = $args{results} or croak "no results defined";
    my $page_size = $args{page_size} || 25;
    my $q         = $args{query} or croak "query required";
    my @results;
    my $count = 0;

    # TODO how to pass in a stemmer if necessary to the ST->parser?
    my $XMLer = Search::Tools::XML->new;
    my $query = Search::Tools->parser()->parse($q);
    my $snipper
        = Search::Tools->snipper( query => $query, as_sentences => 1 );
    my $hiliter = Search::Tools->hiliter( query => $query );
    while ( my $result = $results->next ) {
        my $title   = $XMLer->escape( $result->title   || '' );
        my $summary = $XMLer->escape( $result->summary || '' );

        # \003 is the record-delimiter in Swish3
        # the default behaviour is just to ignore it
        # and replace with a single space, but a subclass (like JSON)
        # might want to split on it to get an array of values
        $title   =~ s/\003/ /g;
        $summary =~ s/\003/ /g;

        my %res = (
            score   => $result->score,
            uri     => $result->uri,
            mtime   => $result->mtime,
            title   => $hiliter->light($title),
            summary => $hiliter->light( $snipper->snip($summary) ),
        );
        for my $field (@$fields) {
            my $str = $XMLer->escape( $result->get_property($field) || '' );
            $str =~ s/\003/ /g;
            $res{$field} = $hiliter->light($str);
        }
        push @results, \%res;
        last if ++$count >= $page_size;
    }
    return \@results;
}

1;

__END__

=head1 NAME

Search::OpenSearch::Engine - abstract base class

=head1 SYNOPSIS

 use Search::OpenSearch::Engine;
 my $engine = Search::OpenSearch::Engine->new(
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
    r           => 1,                   # include results
    format      => 'XML',               # or JSON
    link        => 'http://yourdomain.foo/opensearch/',
 );
 print $response;

=head1 DESCRIPTION

Search::OpenSearch::Engine is an abstract base class. It defines
some sane method behavior based on the SWISH::Prog::Searcher API.

=head1 METHODS

This class is a subclass of Rose::ObjectX::CAF. Only new or overridden
methods are documented here.

=head2 init

Sets up the new object.

=head2 init_searcher

Subclasses must implement this method. If the Searcher object
acts like a SWISH::Prog::Searcher, then search() will Just Work.
Otherwise, your Engine subclass should likely override search() as well.

=head2 search( I<args> )

See the SYNOPSIS.

Returns a Search::OpenSearch::Response object based on the format
specified in I<args>.

=head2 set_limit( I<args> )

Called internally by search(). The I<args> will be three key/value pairs,
with keys "field," "low", and "high".

=head2 facets

Get/set a Search::OpenSearch::Facets object.

=head2 index

Get/set the location of the inverted indexes to be searched. The value
is intented to be used in init_searcher().

=head2 searcher

The value returned by init_searcher().

=head2 fields

Get/set the arrayref of field names to be fetched for each search result.

=head2 type

Should return a unique identifier for your Engine subclass.
Default is to croak().

=head2 link

The base URI for Responses. Passed to Response->link.

=head2 get_facets( I<query>, I<results> )

Checks the cache for facets related to I<query> and, if found,
returns them. If not found, calls build_facets(), which must
be implemented by each Engine subclass.

=head2 build_facets( I<query>, I<results> )

Default will croak. Engine subclasses must implement this method
to provide Facet support.

=head2 build_results( I<results> )

I<results> should be an iterator like SWISH::Prog::Results.

Returns an array ref of hash refs, each corresponding to a single
search result.

=head2 cache

Get/set the internal CHI object. Defaults to the File driver.

=head2 cache_ttl

Get/set the cache key time-to-live. Default is 1 hour.

=cut

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-opensearch at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-OpenSearch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::OpenSearch


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

