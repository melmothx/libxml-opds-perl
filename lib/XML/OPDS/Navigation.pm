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

=cut

has id => (is => 'ro', isa => Str);

has rel => (is => 'ro',
            isa => Enum[qw/self start up subsection/],
            default => 'subsection');

has title => (is => 'ro', isa => Str);

has href => (is => 'ro', isa => Str, required => 1);

has acquisition => (is => 'ro', isa => Bool, default => sub { 0 });

has description => (is => 'ro', isa => Str);

has updated => (is => 'rw', isa => InstanceOf['DateTime'],
                default => sub { return DateTime->now });

sub link_type {
    my $self = shift;
    my $kind = $self->acquisition ? 'acquisition' : 'navigation';
    return "application/atom+xml;profile=opds-catalog;kind=$kind";
}

sub as_link {
    my $self = shift;
    my $link = XML::Atom::Link->new(Version => 1.0);
    $link->rel($self->rel);
    $link->href($self->href);
    $link->type($self->link_type);
    return $link;
}

sub identifier {
    my $self = shift;
    return $self->id || $self->href;
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
