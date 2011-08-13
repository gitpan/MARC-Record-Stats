use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MARC::Record::Stats',
    license             => 'perl',
    dist_author         => q{Andrei V. Toutoukine <tut@isuct.ru>},
    dist_version_from   => 'lib/MARC/Record/Stats.pm',
    build_requires => {
        'Test::Most' => 0,
    },
    requires			=> {
    	'version'		=> 0,
    	'MARC::Record'	=> 0,
    	'Getopt::Euclid'=> 0,
    },
    add_to_cleanup      => [ 'Marc-Record-Stats-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
