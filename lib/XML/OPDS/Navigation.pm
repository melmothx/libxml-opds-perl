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

sub as_link {
    my $self = shift;
    my $link = XML::Atom::Link->new(Version => 1.0);
    $link->rel($self->rel);
    $link->href($self->href);
    my $kind = $self->acquisition ? 'acquisition' : 'navigation';
    $link->type("application/atom+xml;profile=opds-catalog;kind=$kind");
    return $link;
}


1;
