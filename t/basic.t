#!perl

use strict;
use warnings;
use Test::More;

use XML::OPDS;
use XML::OPDS::Navigation;
use XML::OPDS::Acquisition;

my $root = XML::OPDS::Navigation->new(
                                      rel => 'self',
                                      title => 'Root',
                                      href => '/',
                                     );
my $titles = XML::OPDS::Navigation->new(
                                        title => 'Titles',
                                        description => 'texts sorted by title',
                                        href => '/titles',
                                        acquisition => 1,
                                       );

my $topics = XML::OPDS::Navigation->new(
                                        title => 'Titles',
                                        description => 'texts sorted by topics',
                                        href => '/topics',
                                       );

my $feed = XML::OPDS->new(title => 'OPDS Catalog Root Example',
                          navigations => [$root, $titles, $topics ]);

diag $feed->author;

ok ($feed);
ok ($feed->render);
diag $feed->render;
