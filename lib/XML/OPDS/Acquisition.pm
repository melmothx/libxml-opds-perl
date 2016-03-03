package XML::OPDS::Acquisition;

use strict;
use warnings FATAL => 'all';
use Types::Standard qw/Str ArrayRef InstanceOf Object/;
use Moo;
use DateTime;
use XML::Atom;
use XML::Atom::Person;
use XML::Atom::Entry;

=head1 NAME

XML::OPDS::Acquisition - Acquisition elements for OPDS feeds

=head1 SETTERS/ACCESSORS

=cut

has id => (is => 'ro', isa => Str);

has href => (is => 'ro', isa => Str, required => 1);

has title => (is => 'ro', isa => Str, required => 1);

=head2 authors

An arrayref of either scalars with names, or hashrefs with C<name> and
C<uri> as keys. C<uri> is optional.

=cut

has authors => (is => 'ro', isa => ArrayRef);

has summary => (is => 'ro', isa => Str);

has description => (is => 'ro', isa => Str);

has language => (is => 'ro', isa => Str);

has issued => (is => 'ro', isa => Str);

has publisher => (is => 'ro', isa => Str);

has updated => (is => 'rw', isa => InstanceOf['DateTime'],
                default => sub { return DateTime->now });

has files => (is => 'ro', isa => ArrayRef[Str]);

has thumbnail => (is => 'ro', isa => Str);

has image => (is => 'ro', isa => Str);

has _dc => (is => 'lazy',
            isa => Object,
            default => sub {
                XML::Atom::Namespace->new(dc => 'http://purl.org/dc/elements/1.1/');
            });


sub identifier {
    my $self = shift;
    return $self->id || $self->href;
}

sub authors_as_links {
    my $self = shift;
    my @out;
    if (my $authors = $self->authors) {
        foreach my $author (@$authors) {
            my $hash = ref($author) ? $author : { name => $author };
            if (my $name = $hash->{name}) {
                my $author_obj = XML::Atom::Person->new(Version => 1.0);
                $author_obj->name($hash->{name});
                if (my $uri = $hash->{uri}) {
                    $author_obj->uri($uri);
                }
                push @out,  $author_obj;
            }
        }
    }
    return @out;
}

sub files_as_links {
    my $self = shift;
    my @out;
    my %mime = (
                tex => 'application/x-tex',
                pdf => 'application/pdf',
                html => 'text/html',
                epub => 'application/epub+zip',
                muse => 'text/plain',
                txt => 'text/plain',
                zip => 'application/zip',
                png => 'image/png',
                jpg => 'image/jpeg',
                jpeg => 'image/jpeg',
                mobi => 'application/x-mobipocket-ebook',
               );
    my @all = map { +{ rel => 'acquisition', href => $_ } } @{$self->files};
    die "Missing acquisition links" unless @all;

    if (my $thumb = $self->thumbnail) {
        push @all, { rel => 'image/thumbnail', href => $thumb };
    }
    if (my $image = $self->image) {
        push @all, { rel => 'image', href => $image };
    }
    foreach my $file (@all) {
        my $mime_type;
        if ($file->{href} =~ m/\.(\w+)\z/) {
            my $ext = $1;
            $mime_type = $mime{$ext};
        }
        next unless $mime_type;
        my $link = XML::Atom::Link->new(Version => 1.0);
        $link->rel("http://opds-spec.org/$file->{rel}");
        $link->href($file->{href});
        $link->type($mime_type);
        push @out, $link;
    }
    if (@out) {
        return @out;
    }
    else {
        die "Links are required"
    };
}

sub as_entry {
    my $self = shift;
    my $entry = XML::Atom::Entry->new(Version => 1.0);
    $entry->id($self->identifier);
    $entry->title($self->title);
    $entry->updated($self->updated);
    if (my $lang = $self->language) {
        $entry->set($self->_dc, language => $lang);
    }
    foreach my $author ($self->authors_as_links) {
        $entry->add_author($author);
    }
    if (my $summary = $self->summary) {
        $entry->summary($summary);
    }
    if (my $desc = $self->description) {
        $entry->content($desc);
    }
    foreach my $link ($self->files_as_links) {
        $entry->add_link($link);
    }
    return $entry;
}

1;
