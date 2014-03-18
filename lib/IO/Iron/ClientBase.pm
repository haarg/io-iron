package IO::Iron::ClientBase;

## no critic (Documentation::RequirePodAtEnd)
## no critic (Documentation::RequirePodSections)

use 5.008_001;
use strict;
use warnings FATAL => 'all';

# Global creator
BEGIN {
	# No exports
}

# Global destructor
END {
}

=head1 NAME

IO::Iron::ClientBase - Base package for Client Libraries 
to Iron services IronCache, IronMQ and IronWorker.

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

	# new() in the inheriting sub class.

	sub new {
		my ($class, $params) = @_;
		my $self = IO::Iron::ClientBase->new();
		# Add more keys to the self hash.
		my @self_keys = (
				'caches',        # References to all objects created of class IO::Iron::IronCache::Cache.
				legal_keys(%{$self}),
		);
		use Data::Dumper; print Dumper($self); print Dumper(\@self_keys);
		unlock_keys(%{$self});
		lock_keys_plus(%{$self}, @self_keys);
		my @caches;
		$self->{'caches'} = \@caches;
	
		unlock_keys(%{$self});
		bless $self, $class;
		lock_keys(%{$self}, @self_keys);
	
		return $self;
	}

=cut

use Log::Any  qw{$log};
use Hash::Util qw{lock_keys unlock_keys};
use Carp::Assert::More;
use English '-no_match_vars';

=head1 METHODS

=head2 new

Creator function.

Declares the mandatory items of self hash.

=cut

sub new {
	my ($class) = @_;
	$log->tracef('Entering new(%s)', $class);
	my $self = {};
	# These config items are used every time when a connection to REST is made.
	my @self_keys = ( ## no critic (CodeLayout::ProhibitQuotedWordLists)
		'project_id',            # The ID of the project to use for requests.
		'connection',            # Reference to a IO::Iron::Connection object.
		'last_http_status_code', # Contains the HTTP return code after a successful call to the remote host.
	);
	bless $self, $class;
	lock_keys(%{$self}, @self_keys);

	$log->tracef('Exiting new: %s', $self);
	return $self;
}

# INTERNAL METHODS
# For use in the inheriting subclass

# None here.


=head1 AUTHOR

Mikko Koivunalho, C<< <mikko.koivunalho at iki.fi> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-io-iron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-Iron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::Iron::ClientBase


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
And well implemented.


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

1; # End of IO::Iron::ClientBase
