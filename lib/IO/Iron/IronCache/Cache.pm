package IO::Iron::IronCache::Cache;

## no critic (Documentation::RequirePodAtEnd)
## no critic (Documentation::RequirePodSections)
## no critic (ControlStructures::ProhibitPostfixControls)
## no critic (Subroutines::RequireArgUnpacking)

use 5.008_001;
use strict;
use warnings FATAL => 'all';

# Global creator
BEGIN {
	# Export Nothing
}

# Global destructor
END {
}

=head1 NAME

IO::Iron::IronCache::Cache - IronCache (Online Item-Value Storage) Client (Cache).

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

use IO::Iron::Common;
use IO::Iron::IronCache::Api;

# CONSTANTS for this module

# DEFAULTS


=head1 SUBROUTINES/METHODS

=head2 new

=over

=item Creator function.

=back

=cut

sub new {
	my ($class, $params) = @_;
	$log->tracef('Entering new(%s, %s)', $class, $params);
	my $self;
	my @self_keys = ( ## no critic (CodeLayout::ProhibitQuotedWordLists)
			'ironcache_client',      # Reference to IronCache client
			'name',                  # Cache name
			'connection',            # Reference to REST client
			'last_http_status_code', # After successfull network operation, the return value is here.
	);
	lock_keys(%{$self}, @self_keys);
	$self->{'ironcache_client'} = defined $params->{'ironcache_client'} ? $params->{'ironcache_client'} : undef;
	$self->{'name'} = defined $params->{'name'} ? $params->{'name'} : undef;
	$self->{'connection'} = defined $params->{'connection'} ? $params->{'connection'} : undef;
	assert_isa( $self->{'ironcache_client'}, 'IO::Iron::IronCache::Client' , 'self->{ironcache_client} is IO::Iron::IronCache::Client.');
	assert_nonblank( $self->{'name'}, 'self->{name} is defined and is not blank.' );
	assert_isa( $self->{'connection'}, 'IO::Iron::Connection' , 'self->{connection} is IO::Iron::Connection.');

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

=item name         Cache name.

=back

=cut

sub name { return $_[0]->_access_internal('name', $_[1]); }

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

=head2 clear

Deletes all items in an IronCache cache.

=over 8

=item Params: [NONE]

=item Return: 1 == success.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub clear {
	my $self = shift;
	my %params = validate(
		@_, {
			# No parameters
		}
	);
	$log->tracef('Entering clear()');

	my $cache_name = $self->name();
	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronCache::Api::IRONCACHE_CLEAR_A_CACHE(),
			{
				'{Cache Name}' => $cache_name,
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;

	$log->tracef('Exiting clear: %d', 1);
	return 1;
}

=head2 put

=over

=item Params: key, IO::Iron::IronCache::Item object.

=item Return: 1 == success.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub put {
	my $self = shift;
	my %params = validate(
		@_, {
			'key' => { type => SCALAR, }, # cache item key.
			'item' => { isa => 'IO::Iron::IronCache::Item', }, # cache item.
		}
	);
	$log->tracef('Entering put(%s)', \%params);

	my $cache_name = $self->name();
	my $connection = $self->{'connection'};
	my %item_body;
	foreach my $field_name (keys %{ IO::Iron::IronCache::Api::IRONCACHE_PUT_AN_ITEM_INTO_A_CACHE()->{'request_fields'}}) {
		if (defined $params{'item'}->{$field_name}) {
			$item_body{$field_name} = $params{'item'}->{$field_name};
		};
	}
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronCache::Api::IRONCACHE_PUT_AN_ITEM_INTO_A_CACHE(),
			{
				'{Cache Name}' => $cache_name,
				'{Key}'        => $params{'key'},
				'body'         => \%item_body,
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;

	$log->tracef('Exiting put: %d', 1);
	return 1;
}

=head2 increment

=over

=item Params: key, increment (integer number, can be negative).

=item Return: the new value.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub increment {
	my $self = shift;
	my %params = validate(
		@_, {
			'key' => { type => SCALAR, }, # cache item key.
			'increment' => { type => SCALAR, }, # cache item increment.
		}
	);
	assert_nonblank( $params{'key'}, 'key is defined and is not blank.' );
	assert_integer( $params{'increment'}, 'increment amount is integer.');
	$log->tracef('Entering put(%s)', \%params);

	my $cache_name = $self->name();
	my $connection = $self->{'connection'};
	my %item_body;
	$item_body{'amount'} = $params{'increment'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronCache::Api::IRONCACHE_INCREMENT_AN_ITEMS_VALUE(),
			{
				'{Cache Name}' => $cache_name,
				'{Key}'        => $params{'key'},
				'body'         => \%item_body,
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;
	my $new_value = $response_message->{'value'};

	$log->tracef('Exiting increment: %d', $new_value);
	return $new_value;
}

=head2 get

=over

=item Params: key.

=item Return: IO::Iron::IronCache::Item object.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub get {
	my $self = shift;
	my %params = validate(
		@_, {
			'key' => { type => SCALAR, }, # cache item key.
		}
	);
	assert_nonblank( $params{'key'}, 'key is defined and is not blank.' );
	$log->tracef('Entering get(%s)', \%params);

	my $cache_name = $self->name();
	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronCache::Api::IRONCACHE_GET_AN_ITEM_FROM_A_CACHE(),
			{
				'{Cache Name}' => $cache_name,
				'{Key}'        => $params{'key'},
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;
	my $new_item = IO::Iron::IronCache::Item->new(
		'value' => $response_message->{'value'},
		'cas' => $response_message->{'cas'},
	);
	$new_item->expires_in($response_message->{'expires_in'}) if defined $response_message->{'expires_in'};
	$new_item->replace($response_message->{'replace'}) if defined $response_message->{'replace'};
	$new_item->add($response_message->{'add'}) if defined $response_message->{'add'};

	$log->tracef('Exiting get: %s', $new_item);
	return $new_item;
}

=head2 delete

=over

=item Params: key.

=item Return: 1 if successful.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub delete { ## no critic (Subroutines::ProhibitBuiltinHomonyms)
	my $self = shift;
	my %params = validate(
		@_, {
			'key' => { type => SCALAR, }, # cache item key.
		}
	);
	assert_nonblank( $params{'key'}, 'key is defined and is not blank.' );
	$log->tracef('Entering delete(%s)', \%params);

	my $cache_name = $self->name();
	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronCache::Api::IRONCACHE_DELETE_AN_ITEM_FROM_A_CACHE(),
			{
				'{Cache Name}' => $cache_name,
				'{Key}'        => $params{'key'},
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;

	$log->tracef('Exiting delete: %d', 1);
	return 1;
}


=head1 AUTHOR

Mikko Koivunalho, C<< <mikko.koivunalho at iki.fi> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-io-iron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-Iron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::Iron::IronCache


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

1; # End of IO::Iron::IronCache::Cache
