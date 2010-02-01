#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Search::OpenSearch' );
}

diag( "Testing Search::OpenSearch $Search::OpenSearch::VERSION, Perl $], $^X" );
