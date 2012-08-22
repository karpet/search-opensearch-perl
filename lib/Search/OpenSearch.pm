package Search::OpenSearch;

use warnings;
use strict;
use Carp;

our $VERSION = '0.19';

sub engine {
    my $class = shift;
    my %args  = @_;
    my $type  = delete $args{type} or croak "type required";
    my $engine_class
        = $type =~ s/^\+//
        ? $type
        : 'Search::OpenSearch::Engine::' . $type;
    eval "use $engine_class";
    if ($@) {
        croak $@;
    }
    return $engine_class->new(%args);
}

1;

__END__

=head1 NAME

Search::OpenSearch - provide search results in OpenSearch format

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
    c           => 0,                   # count total only (same as f=0 r=0)
    L           => 'field|low|high',    # limit results to inclusive range
    f           => 1,                   # include facets
    r           => 1,                   # include results
    format      => 'XML',               # or JSON
    b           => 'AND',               # or OR
 );
 print $response;

=head1 DESCRIPTION

This module is a work-in-progress. The API is subject to change.

Search::OpenSearch is a framework for various backend engines
to return results comforming to the OpenSearch API (http://opensearch.org/).

=head1 METHODS

=head2 engine( I<args> )

Returns a new Search::OpenSearch::Engine instance.

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


=cut
