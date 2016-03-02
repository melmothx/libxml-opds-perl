#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'XML::OPDS' ) || print "Bail out!\n";
}

diag( "Testing XML::OPDS $XML::OPDS::VERSION, Perl $], $^X" );
