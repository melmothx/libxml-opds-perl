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

has title => (is => 'rw',
              isa => Str,
              required => 1);

has id => (is => 'rw', isa => Str);

has navigations => (is => 'rw', isa => ArrayRef[InstanceOf['XML::OPDS::Navigation']]);

has acquisitions => (is => 'rw', isa => ArrayRef[InstanceOf['XML::OPDS::Acquisition']]);

has updated => (is => 'rw', isa => InstanceOf['DateTime'],
                default => sub { return DateTime->now });

has author => (is => 'rw', isa => Str, default => sub { __PACKAGE__ . ' ' . $VERSION });

=head1 METHODS

=head2 render

Return the generated xml.

=cut

sub self_navigation {
    my $self = shift;
    if (my $navs = $self->navigations) {
        my ($first) = grep { $_->rel eq 'self' } @$navs;
        return $first;
    }
    else {
        die "Missing navigation elements!";
    }
}

sub render {
    my $self = shift;
    my $feed = XML::Atom::Feed->new(Version => 1.0);
    $feed->add_link($self->self_navigation->as_link);
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
