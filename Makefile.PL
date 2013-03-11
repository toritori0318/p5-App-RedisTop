use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'App::RedisTop',
    AUTHOR        => 'toritori0318 <toritori0318@gmail.com>',
    VERSION_FROM  => 'lib/App/RedisTop.pm',
    PREREQ_PM     => {
        'Getopt::Long'      => '0',
        'Pod::Usage'        => '0',
        'IO::Socket::INET'  => '0',
        'Test::More'        => '0',
    },
    MIN_PERL_VERSION => '5.008001',
    LICENSE => 'perl',
    EXE_FILES => [ 'bin/redis-top' ],
);
