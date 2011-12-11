#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Rajce' ) || print "Bail out!\n";
}

diag( "Testing Net::Rajce $Net::Rajce::VERSION, Perl $], $^X" );
