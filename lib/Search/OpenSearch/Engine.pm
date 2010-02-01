package Search::OpenSearch::Engine;
use strict;
use warnings;
use Carp;
use base qw( Rose::ObjectX::CAF );
use Search::OpenSearch::Response::XML;
use Search::OpenSearch::Response::JSON;

__PACKAGE__->mk_accessors(qw( type index facets searcher fields ));

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->searcher( $self->init_searcher() );
    return $self;
}
sub init_searcher { croak "$_[0] does not implement init_searcher()" }

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
        ? $response_class->new( total => $response->hits )
        : $response_class->new(
        results => $results,
        facets  => $self->facets,
        fields  => $self->fields,
        );
    return $response;
}

sub set_limit {
    my $self  = shift;
    my %args  = @_;
    my @range = ( $args{field}, $args{lower}, $args{upper} );
    return \@range;
}

1;
