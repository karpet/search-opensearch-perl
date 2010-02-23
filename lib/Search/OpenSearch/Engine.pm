package Search::OpenSearch::Engine;
use strict;
use warnings;
use Carp;
use base qw( Rose::ObjectX::CAF );
use Scalar::Util qw( blessed );
use Search::OpenSearch::Facets;
use Search::OpenSearch::Response::XML;
use Search::OpenSearch::Response::JSON;
use CHI;

__PACKAGE__->mk_accessors(qw( index facets fields link cache cache_ttl ));

our $VERSION = '0.05';

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

    my $offset         = $args{'o'} || 0;
    my $sort_by        = $args{'s'} || 'score DESC';
    my $page_size      = $args{'p'} || 25;
    my $apply_hilite   = $args{'h'} || 1;
    my $count_only     = $args{'c'} || 0;
    my $limits         = $args{'L'} || [];
    my $include_facets = $args{'f'} || 1;

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
    my $response
        = $count_only
        ? $response_class->new( total => $results->hits )
        : $response_class->new(
        results   => $results,
        facets    => $self->get_facets( $query, $results ),
        fields    => $self->fields,
        offset    => $offset,
        page_size => $page_size,
        total     => $results->hits,
        query     => $query,
        link      => $self->link,
        );
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
        $cache->set( $cache_key, $facest, $self->cache_ttl );
    }
    return $facets;
}

sub build_facets {
    croak ref(shift) . " must implement build_facets()";
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

