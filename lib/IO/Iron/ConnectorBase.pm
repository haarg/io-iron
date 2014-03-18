package IO::Iron::ConnectorBase;

## no critic (Documentation::RequirePodAtEnd)
## no critic (Documentation::RequirePodSections)

use 5.008_001;
use strict;
use warnings FATAL => 'all';

# Global creator
BEGIN {
	# Export nothing.
}

# Global destructor
END {
}

=head1 NAME

IO::Iron::ConnectorBase - Base class for the REST API Connector, HTTP interface class.

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';


=head1 SYNOPSIS

This package is for internal use of IO::Iron packages.

=cut

use Log::Any  qw{$log};
use Hash::Util qw{lock_keys unlock_keys};
use Carp;
use Carp::Assert;
use Carp::Assert::More;
use English '-no_match_vars';
use Scalar::Util qw{blessed};


# DEFAULTS


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new

Creator function.

=cut

sub new {
	my ($class) = @_;
	$log->tracef('Entering new(%s)', $class);
	my $self = {};
	my @self_keys = ( ### no critic (CodeLayout::ProhibitQuotedWordLists)
		# No keys.
	);

	bless $self, $class;
	lock_keys(%{$self}, @self_keys);

	$log->tracef('Exiting new: %s', $self);
	return $self;
}

	# Connector needs:
	# all API info
	# params for API.href     => if it's a mock!
	# message body
	# headers: content type, authorization
	# connection params: timeout?, retry?
	# Connector arranges by inself:
	# HTTP REST connection: REST::Client / LWP


=head2 perform_iron_action

=over 8

=item Params: action name, params hash.

=item Return: 1/0 (1 if success, 0 in all failures),
HTTP return code, hash if success/failed request.
If you need to create your own Connector class, start with copying
this routine.

=back

=cut

sub perform_iron_action {
	#my ($self, $iron_action, $params) = @_;
	#if(!defined $params){
	#	$params = {};
	#}
	#$log->tracef('Entering ConnectorBase:perform_iron_action(%s, %s)', $iron_action, $params);

	croak('This routine must be replaced in the inheriting sub class.');

	#my ($returned_msg, $http_status_code);
	#$log->tracef('Exiting ConnectorBase:perform_iron_action(): %s', $returned_msg );
	#return $http_status_code, $returned_msg;
}


# INTERNAL METHODS

# No internal methods.


=head1 AUTHOR

Mikko Koivunalho, C<< <mikko.koivunalho at iki.fi> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-io-iron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-Iron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::Iron::ConnectorBase


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-Iron>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-Iron>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IO-Iron>

=item * Search CPAN

L<http://search.cpan.org/dist/IO-Iron/>

=back


=head1 ACKNOWLEDGMENTS

Cool idea, "message queue in the cloud": http://www.iron.io/.

=head1 TODO

=over 4

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Mikko Koivunalho.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of IO::Iron::ConnectorBase
