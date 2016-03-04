package XML::OPDS::Navigation;

use strict;
use warnings FATAL => 'all';
use Types::Standard qw/Str Enum Bool InstanceOf/;
use Moo;
use DateTime;
use XML::Atom::Link;

=head1 NAME

XML::OPDS::Navigation - Navigation elements for OPDS feeds

=head1 SETTERS/ACCESSORS

The all are read-write

=head2 prefix

If provided, every uri will have this string prepended, so you can
just pass URIs like '/path/to/file' and have them consistently turned
to 'http://myserver.org/path/to/file' if you set this to
'http://myserver.org'. See also L<XML::OPDS> C<prefix> method.

=head2 href

Required. The URI of the resource. If prefix is provided it is
prepended on output.

=head2 id

=head2 rel

Defaults to C<subsection>. Permitted values: C<self>, C<start>, C<up>,
C<subsection>. This list is a work in progress and probably incomplete.

=head2 title

=head2 acquistion

Boolean, default to false. Indicates that the C<href> is a leaf feed
with acquisition entries.

=head2 description

HTML allowed.

=head2  updated

A L<DateTime> object with the time of last update.

=head2 prefix



=cut

has id => (is => 'rw', isa => Str);

has rel => (is => 'rw',
            isa => Enum[qw/self start up subsection/],
            default => 'subsection');

has title => (is => 'rw', isa => Str);

has href => (is => 'rw', isa => Str, required => 1);

has acquisition => (is => 'rw', isa => Bool, default => sub { 0 });

has description => (is => 'rw', isa => Str);

has updated => (is => 'rw', isa => InstanceOf['DateTime'],
                default => sub { return DateTime->now });

has prefix => (is => 'rw', isa => Str, default => sub { '' });

=head1 METHODS

The are mostly internals and used by L<XML::OPDS>

=head2 link_type

Depend if C<acquisition> is true of false.

=head2 as_link

The navigation as L<XML::Atom::Link> object.

=head2 identifier

Return the id or the URI.

=head2 as_entry

The navigation as L<XML::Atom::Entry> object.

=cut

sub link_type {
    my $self = shift;
    my $kind = $self->acquisition ? 'acquisition' : 'navigation';
    return "application/atom+xml;profile=opds-catalog;kind=$kind";
}

sub as_link {
    my $self = shift;
    my $link = XML::Atom::Link->new(Version => 1.0);
    $link->rel($self->rel);
    $link->href($self->prefix . $self->href);
    $link->type($self->link_type);
    return $link;
}

sub identifier {
    my $self = shift;
    return $self->id || $self->prefix . $self->href;
}

sub as_entry {
    my $self = shift;
    my $item = XML::Atom::Entry->new(Version => 1.0);
    $item->title($self->title);
    $item->id($self->identifier);
    $item->content($self->description);
    $item->updated($self->updated);
    $item->add_link($self->as_link);
    return $item;
}

1;
