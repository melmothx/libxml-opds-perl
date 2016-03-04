#!perl

use strict;
use warnings;
use Test::More tests => 2;
use Test::Differences;
use Data::Dumper;
use XML::OPDS;
use DateTime;

unified_diff;

my $feed = XML::OPDS->new(prefix => 'http://amusewiki.org');
my $updated = DateTime->new(year => 2016, month => 3, day => 1);

$feed->add_to_navigations_new_level(
                          title => 'Root',
                          href => '/',
                          updated => $updated,
                         );
$feed->add_to_navigations(
                          rel => 'start',
                          title => 'Root',
                          href => '/',
                          updated => $updated,
                         );
$feed->add_to_navigations(
                          title => 'Titles',
                          description => 'texts sorted by title',
                          href => '/titles',
                          acquisition => 1,
                          updated => $updated,
                         );
{
    my $expected =<< 'FEED';
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>http://amusewiki.org/</id>
  <link rel="self" href="http://amusewiki.org/" type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
  <link rel="start" href="http://amusewiki.org/" type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
  <title>Root</title>
  <updated>2016-03-01T00:00:00</updated>
  <author>
    <name>XML::OPDS 0.01</name>
    <uri>http://amusewiki.org</uri>
  </author>
  <entry>
    <title>Titles</title>
    <id>http://amusewiki.org/titles</id>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">texts sorted by title</div>
    </content>
    <updated>2016-03-01T00:00:00</updated>
    <link rel="subsection" href="http://amusewiki.org/titles" type="application/atom+xml;profile=opds-catalog;kind=acquisition"/>
  </entry>
</feed>
FEED
    eq_or_diff($feed->render, $expected, "prefixes ok");
}

$feed->add_to_navigations_new_level(
                          title => 'Titles',
                          description => 'texts sorted by title',
                          href => '/titles',
                          acquisition => 1,
                          updated => $updated,
                         );
$feed->add_to_acquisitions(
                           href => '/second/title',
                           title => 'Second title',
                           files => [ '/second/title.epub' ],
                           updated => $updated,
                          );


{
    my $expected =<< 'FEED';
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>http://amusewiki.org/titles</id>
  <link rel="self" href="http://amusewiki.org/titles" type="application/atom+xml;profile=opds-catalog;kind=acquisition"/>
  <link rel="up" href="http://amusewiki.org/" type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
  <link rel="start" href="http://amusewiki.org/" type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
  <title>Titles</title>
  <updated>2016-03-01T00:00:00</updated>
  <author>
    <name>XML::OPDS 0.01</name>
    <uri>http://amusewiki.org</uri>
  </author>
  <entry>
    <id>http://amusewiki.org/second/title</id>
    <title>Second title</title>
    <updated>2016-03-01T00:00:00</updated>
    <link rel="http://opds-spec.org/acquisition" href="http://amusewiki.org/second/title.epub" type="application/epub+zip"/>
  </entry>
</feed>
FEED
    eq_or_diff($feed->render, $expected, "prefixes ok");
}

