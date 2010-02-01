use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Search::OpenSearch',
    AUTHOR              => q{Peter Karman <karman@cpan.org>},
    VERSION_FROM        => 'lib/Search/OpenSearch.pm',
    ABSTRACT_FROM       => 'lib/Search/OpenSearch.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'JSON'       => 0,
        'Rose::ObjectX::CAF' => 0,
        'Scalar::Util'       => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Search-OpenSearch-*' },
);
