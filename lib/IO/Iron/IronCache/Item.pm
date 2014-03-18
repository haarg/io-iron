package IO::Iron::IronCache::Item;

## no critic (Documentation::RequirePodAtEnd)
## no critic (Documentation::RequirePodSections)
## no critic (Subroutines::RequireArgUnpacking)

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

IO::Iron::IronCache::Item - IronCache (Online Item-Value Storage) Client (Cache Item).

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';


=head1 SYNOPSIS

Please see IO::Iron::IronCache::Client for usage.

=head1 REQUIREMENTS

=cut

use Log::Any  qw($log);
use Hash::Util qw{lock_keys unlock_keys};
use Carp::Assert::More;
use English '-no_match_vars';
use Params::Validate qw(:all);

# CONSTANTS for this module

# DEFAULTS

=head1 SUBROUTINES/METHODS

=head2 new

Creator function.

=cut

sub new {
	my $class = shift;
	my %params = validate(
		@_, {
			'value' => { type => SCALAR, },        # Item value (free text), mandatory, can be empty.
			'expires_in' => { type => SCALAR, optional => 1, },   # How long in seconds to keep the item in the cache before it is deleted.
			'replace' => { type => SCALAR, optional => 1, },      # Only set the item if the item is already in the cache.
			'add' => { type => SCALAR, optional => 1, },          # Only set the item if the item is not already in the cache.
			'cas' => { type => SCALAR, optional => 1, },          # Cas value can only be set when the item is read from the cache.
		}
	);
	$log->tracef('Entering new(%s, %s)', $class, %params);
	my $self;
	my @self_keys = ( ## no critic (CodeLayout::ProhibitQuotedWordLists)
			'value',        # Item value (free text), can be empty.
			'expires_in',   # How long in seconds to keep the item in the cache before it is deleted.
			'replace',      # Only set the item if the item is already in the cache.
			'add',          # Only set the item if the item is not already in the cache.
			'cas',          # Cas value can only be set when the item is read from the cache.
	);
	lock_keys(%{$self}, @self_keys);
	$self->{'value'} = defined $params{'value'} ? $params{'value'} : undef;
	$self->{'expires_in'} = defined $params{'expires_in'} ? $params{'expires_in'} : undef;
	$self->{'replace'} = defined $params{'replace'} ? $params{'replace'} : undef;
	$self->{'add'} = defined $params{'add'} ? $params{'add'} : undef;
	$self->{'cas'} = defined $params{'cas'} ? $params{'cas'} : undef;
	# All of the above can be undefined, except the value.
	assert_defined( $self->{'value'}, 'self->{value} is defined and is not blank.' );
	# If timeout, add or expires_in are undefined, the IronMQ defaults (at the server) will be used.

	unlock_keys(%{$self});
	my $blessed_ref = bless $self, $class;
	lock_keys(%{$self}, @self_keys);

	$log->tracef('Exiting new: %s', $blessed_ref);
	return $blessed_ref;
}

=head2 Getters/setters

Set or get a property.
When setting, returns the reference to the object.

=over 8

=item value        Item value (free text), can be empty.

=item expires_in   How long in seconds to keep the item in the cache before it is deleted.

=item replace      Only set the item if the item is already in the cache.

=item add          Only set the item if the item is not already in the cache.

=item cas          Cas value can only be set when the item is read from the cache.

=back

=cut

sub value { return $_[0]->_access_internal('value', $_[1]); }
sub expires_in { return $_[0]->_access_internal('expires_in', $_[1]); }
sub replace { return $_[0]->_access_internal('replace', $_[1]); }
sub add { return $_[0]->_access_internal('add', $_[1]); }
sub cas { return $_[0]->_access_internal('cas', $_[1]); }

# TODO Move _access_internal() to IO::Iron::Common.

sub _access_internal {
	my ($self, $var_name, $var_value) = @_;
	$log->tracef('_access_internal(%s, %s)', $var_name, $var_value);
	if( defined $var_value ) {
		$self->{$var_name} = $var_value;
		return $self;
	}
	else {
		return $self->{$var_name};
	}
}


=head1 AUTHOR

Mikko Koivunalho, C<< <mikko.koivunalho at iki.fi> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-io-iron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-Iron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::Iron::IronCache::Client


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

1; # End of IO::Iron::IronCache::Item
