use strict;
use warnings;
use ExtUtils::MakeMaker;

my $MM_Version = $ExtUtils::MakeMaker::VERSION;

if ( $MM_Version =~ /_/ )    # dev version
{
    $MM_Version = eval $MM_Version;
    die $@ if ($@);
}

WriteMakefile(
    NAME          => 'Search::OpenSearch',
    AUTHOR        => q{Peter Karman <karman@cpan.org>},
    VERSION_FROM  => 'lib/Search/OpenSearch.pm',
    ABSTRACT_FROM => 'lib/Search/OpenSearch.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'         => 0,
        'JSON'               => 0,
        'Rose::ObjectX::CAF' => 0,
        'Scalar::Util'       => 0,
        'URI::Encode'        => 0,
        'Data::Pageset'      => 0,
        'Search::Tools'      => 0,
        'CHI'                => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Search-OpenSearch-*' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44 ? ()
        : ( META_MERGE => {
                resources => {
                    license  => 'http://dev.perl.org/licenses/',
                    homepage => 'https://github.com/karpet/search-opensearch-perl',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch',
                    repository =>
                        'git://github.com/karpet/search-opensearch-perl.git',
                },
            }
        )
    ),
);
