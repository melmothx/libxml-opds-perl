package XML::OPDS::Acquisition;

use strict;
use warnings FATAL => 'all';
use Types::Standard qw/Str ArrayRef InstanceOf/;
use Moo;
use DateTime;

=head1 NAME

XML::OPDS::Acquisition - Acquisition elements for OPDS feeds

=head1 SETTERS/ACCESSORS

=cut

has id => (is => 'ro', isa => Str);

has title => (is => 'ro', isa => Str);

has description => (is => 'ro', isa => Str);

has files => (is => 'ro', isa => ArrayRef[Str]);

has updated => (is => 'rw', isa => InstanceOf['DateTime'],
                default => sub { return DateTime->now });

1;
