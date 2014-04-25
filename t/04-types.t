#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

use_ok('Search::OpenSearch::Types');

{

    package Foo;
    use Moose;
    use Search::OpenSearch::Types;
    use Types::Standard qw( Maybe );

    has 'facets' => (
        is     => 'rw',
        isa    => Maybe [SOSFacets],
        coerce => 1,
    );

}

ok( my $foo = Foo->new( facets => { bar => 1 } ), "Foo->new" );
