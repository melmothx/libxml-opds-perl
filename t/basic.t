#!perl

use strict;
use warnings;
use Test::More tests => 2;
use Test::Differences;
use XML::OPDS;
use XML::OPDS::Navigation;
use XML::OPDS::Acquisition;
use DateTime;

unified_diff;

my $updated = DateTime->new(year => 2016, month => 3, day => 1);

my $root = XML::OPDS::Navigation->new(
                                      rel => 'self',
                                      title => 'Root',
                                      href => '/',
                                      updated => $updated,
                                     );
my $start = XML::OPDS::Navigation->new(
                                      rel => 'start',
                                      title => 'Root',
                                      href => '/',
                                      updated => $updated,
                                     );

my $titles = XML::OPDS::Navigation->new(
                                        title => 'Titles',
                                        description => 'texts sorted by title',
                                        href => '/titles',
                                        acquisition => 1,
                                        updated => $updated,
                                       );

my $topics = XML::OPDS::Navigation->new(
                                        title => 'Topics',
                                        description => 'texts sorted by topics',
                                        href => '/topics',
                                        updated => $updated,
                                       );

{
    my $feed = XML::OPDS->new(title => 'OPDS Catalog Root Example',
                              updated => $updated,
                              navigations => [$root, $start, $titles, $topics ]);

    ok ($feed, "Object created ok");
    my $expected =<< 'FEED';
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>/</id>
  <link rel="self" href="/" type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
  <link rel="start" href="/" type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
  <title>OPDS Catalog Root Example</title>
  <updated>2016-03-01T00:00:00</updated>
  <author>
    <name>XML::OPDS 0.01</name>
    <uri>http://amusewiki.org</uri>
  </author>
  <entry>
    <title>Titles</title>
    <id>/titles</id>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">texts sorted by title</div>
    </content>
    <updated>2016-03-01T00:00:00</updated>
    <link rel="subsection" href="/titles" type="application/atom+xml;profile=opds-catalog;kind=acquisition"/>
  </entry>
  <entry>
    <title>Topics</title>
    <id>/topics</id>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">texts sorted by topics</div>
    </content>
    <updated>2016-03-01T00:00:00</updated>
    <link rel="subsection" href="/topics" type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
  </entry>
</feed>
FEED
    eq_or_diff($feed->render, $expected, 'root feed ok');
}

