package IO::Iron::Connection;

## no critic (Documentation::RequirePodAtEnd)
## no critic (Documentation::RequirePodSections)
## no critic (RegularExpressions::RequireLineBoundaryMatching)

use 5.008_001;
use strict;
use warnings FATAL => 'all';

# Global creator
BEGIN {
	# No exports.
}

# Global destructor
END {
}

=head1 NAME

IO::Iron::Connection - Iron.io Connection reference for Perl Client Libraries!

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';


=head1 SYNOPSIS

This package is for internal use of IO::Iron packages.

=cut

use Log::Any  qw{$log};
use Hash::Util qw{lock_keys unlock_keys};
use Carp::Assert;
use Carp::Assert::More;
use English '-no_match_vars';


# DEFAULTS
use constant { ## no critic (ValuesAndExpressions::ProhibitConstantPragma)
	DEFAULT_PROTOCOL => 'https',
	DEFAULT_PORT => 443,
	DEFAULT_HOST_PATH_PREFIX => '/1',
	DEFAULT_TIMEOUT => 3,
};


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new

Creator function.

=cut

sub new {
	my ($class, $params) = @_;
	$log->tracef('Entering new(%s, %s)', $class, $params);
	my $self;
	my @self_keys = ( ## no critic (CodeLayout::ProhibitQuotedWordLists)
			'project_id',    # The ID of the project to use for requests.
			'token',         # The OAuth token that should be used to authenticate requests. Can be found in the HUD.
			'host',          # The domain name the API can be located at. Defaults to a product-specific value, but always using Amazon's cloud.
			'protocol',      # The protocol that will be used to communicate with the API. Defaults to "https", which should be sufficient for 99% of users.
			'port',          # The port to connect to the API through. Defaults to 443, which should be sufficient for 99% of users.
			'api_version',   # The version of the API to connect through. Defaults to the version supported by the client. End-users should probably never change this.
			'host_path_prefix', # Path prefix to the RESTful url. Defaults to '/1'. Used with non-standard clouds/emergency service back up addresses.
			'timeout',       # REST client timeout (for REST calls accessing Iron services)
			'connector',     # Reference to the object which does the actual REST client calls, or mocks them.
	);
	lock_keys(%{$self}, @self_keys);
	$log->debugf('The params: %s', $params);
	$self->{'project_id'} = defined $params->{'project_id'} ? $params->{'project_id'} : undef;
	$self->{'token'} = defined $params->{'token'} ? $params->{'token'} : undef;
	$self->{'host'} = defined $params->{'host'} ? $params->{'host'} : undef;
	$self->{'protocol'} = defined $params->{'protocol'} ? $params->{'protocol'} : DEFAULT_PROTOCOL();
	$self->{'port'} = defined $params->{'port'} ? $params->{'port'} : DEFAULT_PORT();
	$self->{'api_version'} = defined $params->{'api_version'} ? $params->{'api_version'} : undef;
	$self->{'host_path_prefix'} = defined $params->{'host_path_prefix'} ? $params->{'host_path_prefix'} : DEFAULT_HOST_PATH_PREFIX();
	$self->{'timeout'} = defined $params->{'timeout'} ? $params->{'timeout'} : DEFAULT_TIMEOUT();
	# Set up the connector object.
	if(defined $params->{'connector'}) {
		$self->{'connector'} = $params->{'connector'}; # The connector has been instantiated for us.
	}
	else {
		require IO::Iron::Connector;
		$self->{'connector'} = IO::Iron::Connector->new();
	}

	unlock_keys(%{$self});
	bless $self, $class;
	lock_keys(%{$self}, @self_keys);

	#$self->_assert_configuration($self);

	$log->infof('IO::Iron::Connection client created with config: (project_id=%s; token=%s; host=%s; protocol=%s; port=%s; host_path_prefix=%s; timeout=%s).',
		$self->{'project_id'}, $self->{'token'}, $self->{'host'}, $self->{'protocol'}, $self->{'port'}, $self->{'host_path_prefix'}, $self->{'timeout'});
	$log->tracef('Exiting new: %s', $self);
	return $self;
}

=head2 perform_iron_action

=over 8

=item Params: action name, params hash.

=item Return: 1/0 (1 if success, 0 in all failures), 
HTTP return code, hash if success/failed request.

=back

=cut

sub perform_iron_action {
	my ($self, $iron_action, $params) = @_;
	if(!defined $params) {
		$params = {};
	}
	$log->tracef('Entering perform_iron_action(%s, %s)', $iron_action, $params);
	$self->_assert_configuration();

	my $href = $iron_action->{'href'};
	my $action_verb = $iron_action->{'action'};
	my $retry = $iron_action->{'retry'};
	my $require_body = $iron_action->{'require_body'};
	my $paged = $iron_action->{'paged'} ? $iron_action->{'paged'} : 0;
	my $per_page = $iron_action->{'per_page'} ? $iron_action->{'per_page'} : 0;
	my $log_message = $iron_action->{'log_message'} ? $iron_action->{'log_message'} : q{};
	my $request_fields = $iron_action->{'request_fields'} ? $iron_action->{'request_fields'} : {};
	my $content_type = $iron_action->{'content_type'};

	$params->{'{Protocol}'} = $self->{'protocol'};
	$params->{'{Port}'} = $self->{'port'};
	$params->{'{Host}'} = $self->{'host'};
	$params->{'{Project ID}'} = $self->{'project_id'};
	$params->{'{Host Path Prefix}'} = $self->{'host_path_prefix'};
	$params->{'{Api Version}'} = $self->{'api_version'};
	$params->{'authorization_token'} = $self->{'token'};
	$params->{'http_client_timeout'} = $self->{'timeout'};
	$params->{'content_type'} = $content_type;

	my $connector = $self->{'connector'};
	my ($http_status_code, $returned_msg) = $connector->perform_iron_action($iron_action, $params);

	# Logging
	foreach my $key (sort keys %{$params}) {
		my $value = $params->{$key};
		$log_message =~ s/$key/$value/gs; ## no critic (RegularExpressions::RequireExtendedFormatting)
	};
	foreach my $key (sort keys %{$request_fields}) {
		my $field_name = $request_fields->{$key};
		my $field_value = $params->{'body'}->{$key} ? $params->{'body'}->{$key} : q{};
		$log_message =~ s/$field_name/$field_value/gs; ## no critic (RegularExpressions::RequireExtendedFormatting)
	};
	$log->info($log_message);
	$log->tracef('Exiting perform_iron_action(): %s', $returned_msg );
	return $http_status_code, $returned_msg;
}

# INTERNAL METHODS

# Assert that all the configuration is valid before making any network operation.
sub _assert_configuration {
	my ($self) = @_;
	$log->tracef('Entering _assert_configuration(%s)', $self);

	my $rval = 1;
	assert_nonblank( $self->{'project_id'}, 'self->{project_id} is defined and not blank.' );
	assert_nonblank( $self->{'token'}, 'self->{token} is defined and not blank.' );
	assert_nonblank( $self->{'host'}, 'self->{host} is defined and not blank.' );
	assert_nonblank( $self->{'protocol'}, 'self->{protocol} is defined and not blank.' );
	assert_nonblank( $self->{'port'}, 'self->{port} is defined and not blank.' );
	# api_version does not require a value. No default value available.
	assert_nonblank( $self->{'host_path_prefix'}, 'self->{host_path_prefix} is defined and not blank.' );
	#assert_nonblank( $self->{'timeout'}, 'self->{timeout} is defined and not blank.' );
	assert_nonnegative_integer( $self->{'timeout'}, 'self->{timeout} is a nonnegative integer.' );
	assert_isa( $self->{'connector'}, 'IO::Iron::ConnectorBase', 'self->{connector} is a descendant of IO::Iron::ConnectorBase.' );

	$log->tracef('Exiting _assert_configuration(): %d', $rval);
	return $rval;
}

=head1 AUTHOR

Mikko Koivunalho, C<< <mikko.koivunalho at iki.fi> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-io-iron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-Iron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::Iron::Client


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

1; # End of IO::Iron::Connection
