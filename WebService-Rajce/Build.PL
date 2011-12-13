use strict;
use Module::Build;

Module::Build
  ->new( module_name => "WebService::Rajce",
         license     => 'perl',
         bin_files => [ 'bin/rajce-get', 'bin/rajce-put$' ],
				 dist_author         => 'Petr Kletecka <pek@cpan.org>',
				 dist_version_from   => 'lib/WebService/Rajce.pm',

				 configure_requires => {
					 'Module::Build' => 0.38 
				 },
         build_requires => {
             'Test::More'       => 0,
         },
         requires    => {
             'WWW::Mechanize' => 1.50,
             'File::Path'	    => 2.06_05,
             'File::Basename'	=> 1.2,
             'Getopt::Std'		=> 0,
             'Net::Netrc'		=> 1.22,
             'XML::Simple'		=> 0,
             'Encode'		=> 0,
             'Image::Magick'		=> 0,
             'Digest::MD5'		=> 0,
         },
         create_makefile_pl => 'traditional',
       )
  ->create_build_script;
