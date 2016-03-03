package XML::OPDS;

use strict;
use warnings FATAL => 'all';
use Types::Standard qw/Str Object ArrayRef InstanceOf/;
use Moo;
use DateTime;
use XML::Atom;
use XML::Atom::Feed;
use XML::Atom::Entry;

=head1 NAME

XML::OPDS - OPDS Feed creation

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use XML::OPDS;

    my $feed = XML::OPDS->new(title => 'OPDS root', ... );
    my $xml = $feed->render;

=head1 SETTERS/ACCESSORS

=cut

has navigations => (is => 'rw', isa => ArrayRef[InstanceOf['XML::OPDS::Navigation']]);
has acquisitions => (is => 'rw', isa => ArrayRef[InstanceOf['XML::OPDS::Acquisition']]);
has author => (is => 'rw', isa => Str, default => sub { __PACKAGE__ . ' ' . $VERSION });
has author_uri => (is => 'rw', isa => Str, default => sub { 'http://amusewiki.org' });

=head1 METHODS

=head2 render

Return the generated xml.

=cut

sub start_navigation {
    return shift->navigation_hash->{start};
}

sub self_navigation {
    return shift->navigation_hash->{self};
}

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
        if ($rel eq 'start' or $rel eq 'self') {
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

sub render {
    my $self = shift;
    my $feed = XML::Atom::Feed->new(Version => 1.0);
    my $main = $self->self_navigation;
    $feed->id($main->identifier);
    $feed->add_link($main->as_link);
    $feed->add_link($self->start_navigation->as_link);
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
        # if it's an acquisition feed, stuff the links in the feed.
        foreach my $link ($self->navigation_entries) {
            $feed->add_link($link->as_link);
        }
    }
    else {
        # othewise use the links to create entries
        foreach my $entry ($self->navigation_entries) {
            $feed->add_entry($entry->as_entry);
        }
    }
    return $feed->as_xml;
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
