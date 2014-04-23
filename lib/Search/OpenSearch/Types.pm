package Search::OpenSearch::Types;
use Type::Tiny;
use Types::Standard qw( HashRef Object );
use Type::Utils qw( declare as where inline_as coerce from );

# singleton types
my $FACETS = declare as Object;
coerce $FACETS, from HashRef, q{ Search::OpenSearch::Facets->new($_) };

sub facets { return $FACETS }

1;

=head1 NAME

Search::OpenSearch::Types - attribute types for Search::OpenSearch

=head1 SYNOPSIS

 package Foo;
 use Search::OpenSearch::Types;

 has 'facets' => (
    is     => 'rw',
    isa    => Maybe [ InstanceOf ['Search::OpenSearch::Facets'] ],
    coerce => Search::OpenSearch::Types->facets->coercion,
 );

 1;

=head1 METHODS

=head2 facets

Returns Type::Tiny object for B<facets> type.

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

Copyright 2014 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
