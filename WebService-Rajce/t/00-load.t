#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::Rajce' ) || print "Bail out!\n";
}

diag( "Testing WebService::Rajce $WebService::Rajce::VERSION, Perl $], $^X" );
