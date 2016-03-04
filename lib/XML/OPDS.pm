package XML::OPDS;

use strict;
use warnings FATAL => 'all';
use Types::Standard qw/Str Object ArrayRef InstanceOf/;
use Moo;
use DateTime;
use XML::Atom;
use XML::Atom::Feed;
use XML::Atom::Entry;
use XML::OPDS::Navigation;
use XML::OPDS::Acquisition;

=head1 NAME

XML::OPDS - OPDS (Open Publication Distribution System) feed creation

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 DESCRIPTION

This module facilitates the creation of OPDS feeds.

The specifications can be found at L<http://opds-spec.org/> while the
validator is at L<http://opds-validator.appspot.com/>.

The idea is that it should be enough to pass the navigation links and
the title entries with some data, and have the feed back.

The OPDS feeds are basically Atom feeds, hence this module uses
L<XML::Atom> under the hood.

Some features are not supported yet, but patches are welcome. Also
keep in mind that the applications which are supposed to talk to your
server have a level of support which varies from decent to "keep
crashing".

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

  use XML::OPDS;
  my $feed = XML::OPDS->new(prefix => 'http://amusewiki.org');
  # add two links, self and start are mandatory.
  $feed->add_to_navigations(
                            rel => 'self',
                            title => 'Root',
                            href => '/',
                           );
  $feed->add_to_navigations(
                            rel => 'start',
                            title => 'Root',
                            href => '/',
                           );
  # add a navigation for the title list, marking as leaf, where the
  # download links can be retrieved.
  $feed->add_to_navigations(
                            title => 'Titles',
                            description => 'texts sorted by title',
                            href => '/titles',
                            acquisition => 1,
                           );
  # and render
  print $feed->render;
  # you can reuse the object for leaf feeds (i.e. the acquistion
  # feeds), pushing another self navigation, which will replace the
  # previous one.
  $feed->add_to_navigations(
                            rel => 'self',
                            title => 'Titles',
                            description => 'texts sorted by title',
                            href => '/titles',
                            acquisition => 1,
                           );
  $feed->add_to_acquisitions(
                             href => '/my/title',
                             title => 'My title',
                             files => [ '/my/title.epub' ],
                            );
  # and here we have an acquisition feed, because of the presence of
  # the acquisition.
  print $feed->render;

=head1 ENCODING

Even if the module wants characters as input (decoded strings, not
bytes), the output XML is an UTF-8 encoded string.

=head1 SETTERS/ACCESSORS

=head2 navigations

Arrayref of L<XML::OPDS::Navigation> objects. An object with a rel
C<self> (the feed itself) and one with the rel C<start> (the root
feed) are mandatory. If not present, the module will crash while
rendering the feed.

=head2 acquisitions

Arrayref of L<XML::OPDS::Acquisition> objects. If one or more objects
are present, the feed will become an acquistion feed.

=head2 author

The producer of the feed. Defaults to this class name and version.

=head2 author_uri

The uri of the author. Defaults to L<http://amusewiki.org> (which is
the home of this class).

=head2 prefix

Default to the empty string. On instances of this class, by itself has
no effect. However, when calling C<add_to_acquisitions> and
C<add_to_navigations>, it will be passed to the constructors of those
objects.

This is usually the hostname of the OPDS server. So you need just to
pass, e.g. 'http://amusewiki.org' and have all the links prefixed by
that (no slash mangling or adding is performed). If you are going to
pass the full urls, leave it at the default.

=head1 METHODS

=head2 render

Return the generated xml.

=head2 atom

Return the L<XML::Atom::Feed> object.

=head2 create_navigation(%args)

Create a L<XML::OPDS::Navigation> object inheriting the prefix.

=head2 create_acquisition(%args)

Create a L<XML::OPDS::Acquisition> object inheriting the prefix.

=head2 add_to_navigations(%args)

Call C<create_navigation> and add it to the C<navigations> stack.

If a navigation with the attribute C<rel> set to C<self> was already
added, the new one will become the new C<self>, while the old one will
become an C<up> rel.

This is designed to play well with chained actions (so you can reuse
the object, stack selfs, and the result will be correct).

=head2 add_to_acquisitions(%args)

Call C<create_acquisition> and add it to the C<acquisition> stack.

=head1 INTERNAL METHODS

=head2 navigation_entries

Return a list of L<XML::OPDS::Navigation> objects excluding C<self>
and C<start>.

=head2 navigation_hash

Return an hashref, where the keys are the C<rel> attributes of the
navigation objects. The value is an object if the navigation is meant
to be unique, or an arrayref of objects if not so.

=head2 is_acquisition

Return true if there are acquisition objects stacked.

=cut

has navigations => (is => 'rw', isa => ArrayRef[InstanceOf['XML::OPDS::Navigation']], default => sub { [] });
has acquisitions => (is => 'rw', isa => ArrayRef[InstanceOf['XML::OPDS::Acquisition']], default => sub { [] });
has author => (is => 'rw', isa => Str, default => sub { __PACKAGE__ . ' ' . $VERSION });
has author_uri => (is => 'rw', isa => Str, default => sub { 'http://amusewiki.org' });
has prefix => (is => 'rw', isa => Str, default => sub { '' });

sub navigation_entries {
    my $self = shift;
    my $hash = $self->navigation_hash;
    my @others;
    foreach my $k (sort keys %$hash) {
        my $entries = $hash->{$k};
        # exclude the uniques
        if (ref($entries) eq 'ARRAY') {
            push @others, @$entries;
        }
    }
    return @others;
}

sub navigation_hash {
    my $self = shift;
    my $navs = $self->navigations;
    die "Missing navigations" unless $navs && @$navs;
    my %out;
    foreach my $nav (@$navs) {
        my $rel = $nav->rel;
        # uniques
        if ($rel eq 'start' or
            $rel eq 'self'  or
            $rel eq 'up') {
            $out{$rel} = $nav;
        }
        else {
            $out{$rel} ||= [];
            push @{$out{$rel}}, $nav;
        }
    }
    return \%out;
}

sub is_acquisition {
    if (my $acquisitions = shift->acquisitions) {
        return scalar(@$acquisitions);
    }
    else {
        return 0;
    }
}

sub atom {
    my $self = shift;
    my $feed = XML::Atom::Feed->new(Version => 1.0);
    my $main = $self->navigation_hash->{'self'};
    die "Missing self navigation element!" unless $main;
    $feed->id($main->identifier);
    $feed->add_link($main->as_link);
    foreach my $unique (qw/up start/) {
        if (my $nav = $self->navigation_hash->{$unique}) {
            $feed->add_link($nav->as_link);
        }
    }
    $feed->title($main->title);
    $feed->updated($main->updated);
    if (my $author_name = $self->author) {
        my $author = XML::Atom::Person->new(Version => 1.0);
        $author->name($author_name);
        if (my $author_uri = $self->author_uri) {
            $author->uri($author_uri);
        }
        $feed->author($author);
    }
    if ($self->is_acquisition) {
        # if it's an acquisition feed, stuff the links in the feed,
        # but filter out the subsections. And probably other stuff as well.
        foreach my $link ($self->navigation_entries) {
            my %rels = (up => 1, related => 1, alternate => 1);
            $feed->add_link($link->as_link) if $rels{$link->rel};
        }
        foreach my $entry (@{$self->acquisitions}) {
            $feed->add_entry($entry->as_entry);
        }
    }
    else {
        # othewise use the links to create entries
        foreach my $entry ($self->navigation_entries) {
            $feed->add_entry($entry->as_entry);
        }
    }
    return $feed;
}

sub render {
    shift->atom->as_xml;
}

sub create_navigation {
    my $self = shift;
    return XML::OPDS::Navigation->new(prefix => $self->prefix, @_);
}

sub add_to_navigations {
    my $self = shift;
    my $navigation = $self->create_navigation(@_);
    # turn the previous self in an "up" link.
    if ($navigation->rel eq 'self') {
        foreach my $previous (grep { $_->rel eq 'self' } @{$self->navigations}) {
            print "Turning " . $previous->href . " in up\n";
            $previous->rel('up');
        }
    }
    push @{$self->navigations}, $navigation;
    return $navigation;
}

sub create_acquisition {
    my $self = shift;
    return XML::OPDS::Acquisition->new(prefix => $self->prefix, @_);
}

sub add_to_acquisitions {
    my $self = shift;
    my $acquisition = $self->create_acquisition(@_);
    push @{$self->acquisitions}, $acquisition;
    return $acquisition;
}


=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-opds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-OPDS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::OPDS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-OPDS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-OPDS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-OPDS>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-OPDS/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Marco Pessotto.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of XML::OPDS
