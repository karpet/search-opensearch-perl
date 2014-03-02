package Search::OpenSearch::Response;
use strict;
use warnings;
use base qw( Rose::ObjectX::CAF );
use Carp;
use Data::Pageset;
use overload
    '""'     => sub { $_[0]->stringify; },
    'bool'   => sub {1},
    fallback => 1;

my @attributes = qw(
    engine
    results
    total
    offset
    page_size
    fields
    facets
    query
    parsed_query
    json_query
    title
    link
    author
    search_time
    build_time
    sort_info
    version
    suggestions
);
__PACKAGE__->mk_accessors( @attributes, qw( debug pps error ) );

our $VERSION = '0.30_01';

our %ATTRIBUTES = ();

sub default_fields {
    return [qw( uri title summary mtime score )];
}

sub get_version {
    my $self = shift;
    my $class = ref $self ? ref($self) : $self;
    no strict 'refs';
    return ${"${class}::VERSION"};
}

sub init {
    my $self = shift;

    my $class = ref $self;
    map { $ATTRIBUTES{$class}->{$_} = $_ } @attributes;

    $self->SUPER::init(@_);
    $self->{title}     ||= 'OpenSearch Results';
    $self->{author}    ||= ref($self);
    $self->{link}      ||= '';
    $self->{pps}       ||= 10;
    $self->{offset}    ||= 0;
    $self->{page_size} ||= 10;
    $self->{version}   ||= $self->get_version();
    return $self;
}

sub stringify { croak "$_[0] does not implement stringify()" }

sub as_hash {
    my $self = shift;
    my %hash = map { $_ => $self->$_ } keys %{ $ATTRIBUTES{ ref $self } };
    return \%hash;
}

sub build_pager {
    my $self      = shift;
    my $offset    = $self->offset;
    my $page_size = $self->page_size;
    my $this_page = ( $offset / $page_size ) + 1;
    my $pager     = Data::Pageset->new(
        {   total_entries    => $self->total,
            entries_per_page => $page_size,
            current_page     => $this_page,
            pages_per_set    => $self->pps,
            mode             => 'slide',
        }
    );
    return $pager;
}

sub add_attribute {
    my $self = shift;
    my $class = ref $self ? ref $self : $self;
    for my $attr (@_) {
        $self->mk_accessors($attr);
        $ATTRIBUTES{$class}->{$attr} = $attr;
    }
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
    s           => 'score desc',        # sort order
    o           => 0,                   # offset
    p           => 25,                  # page size
    h           => 1,                   # highlight query terms in results
    c           => 0,                   # return count stats only (no results)
    L           => 'field|low|high',    # limit results to inclusive range
    f           => 1,                   # include facets
    r           => 1,                   # include results
    format      => 'XML',               # or JSON
    b           => 'AND',               # or OR
 );
 print $response;

=head1 DESCRIPTION

Search::OpenSearch::Response is an abstract base class with some
common methods for all Response subclasses.

=head1 METHODS

This class is a subclass of Rose::ObjectX::CAF. Only new or overridden
methods are documented here.

=head2 get_version

Returns the package var $VERSION string by default.

=head2 init

Sets some defaults for a new Response.

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

=item parsed_query

As returned by Search::Query.

=item json_query

Same as parsed_query, but the object tree is JSON encoded instead
of stringified.

=item author

=item pps

Pages-per-section. Used by Data::Pageset. Default is "10".

=item title

=item link

=item search_time

=item build_time

=item engine

=item sort_info

=item version

=item suggestions

=back

=head2 build_pager

Returns Data::Pageset object based on offset() and page_size().

=head2 as_hash

Returns the Response object as a hash ref of key/value pairs.

=head2 stringify

Returns the Response in the chosen serialization format.

Response objects are overloaded to call stringify().

=head2 add_attribute( I<attribute_name> )

Adds get/set method I<attribute_name> to the class and will include
that attribute in as_hash(). This method is intended to make it easier
to extend the basic structure without needing to subclass.

=head2 default_fields 

Returns array ref of default result field names. These are implemented
by the default Engine class.

=head2 error

Get/set error value for the Response. This value is not included
in the stringify() output, but can be used to set or check for
errors in processing.

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
