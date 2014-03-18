package IO::Iron::Common;

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

IO::Iron::Common - Common routines for Client Libraries to Iron services IronCache, IronMQ and IronWorker.

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';


=head1 REQUIREMENTS

=cut

use File::Slurp ();
use Log::Any  qw{$log};
use JSON ();
#use File::Spec qw{read_file};
use File::HomeDir ();
use Hash::Util qw{lock_keys unlock_keys};
use Carp::Assert::More;
use English '-no_match_vars';
use Params::Validate qw(:all);


=head1 FUNCTIONS

Internal functions for use in the Client objects.

=cut

=head2 IRON_CONFIG_KEYS

=cut

sub IRON_CONFIG_KEYS {
	return (
		'project_id',       # The ID of the project to use for requests.
		'token',            # The OAuth token that should be used to authenticate requests. Can be found in the HUD.
		'host',             # The domain name the API can be located at. Defaults to a product-specific value, but always using Amazon's cloud.
		'protocol',         # The protocol that will be used to communicate with the API. Defaults to "https", which should be sufficient for 99% of users.
		'port',             # The port to connect to the API through. Defaults to 443, which should be sufficient for 99% of users.
		'api_version',      # The version of the API to connect through. Defaults to the version supported by the client. End-users should probably never change this.
		'host_path_prefix', # Path prefix to the RESTful url. Defaults to '/1'. Used with non-standard clouds/emergency service back up addresses.
		'timeout',          # REST client timeout (for REST calls accessing IronMQ). N.B. This is not a IronMQ config option! It only configures client this client.
	);
}

=head2 IRON_CLIENT_PARAMETERS

=cut

sub IRON_CLIENT_PARAMETERS {
	return (
			IRON_CONFIG_KEYS(),
			'config',            # The config file name.
			'connector',         # Pointer to a preinitiated connector object.
	);
}

=head2 get_config

Get the config from file or from system environmental variables.
Follows the global configuration scheme as explained in http://dev.iron.io/mq/reference/configuration/.

The configuration is constructed as follows:

=over 8

=item 1. The global configuration file sets the defaults according to the file hierarchy. (.iron.json in home folder)

=item 2. The global environment variables overwrite the global configuration file's values.

=item 3. The product-specific environment variables overwrite everything before them.

=item 4. The local configuration file overwrites everything before it according to the file hierarchy. (iron.json in the same directory as the script being run)

=item 5. The configuration file specified when instantiating the client library overwrites everything before it according to the file hierarchy.

=item 6. The arguments passed when instantiating the client library overwrite everything before them.

=back

Return: ref to %config.

=cut

sub get_config { ## no critic (Subroutines::RequireArgUnpacking)
	my %params = validate(
		@_, {
			map { $_ => { type => SCALAR, optional => 1 }, } IRON_CONFIG_KEYS(), ## no critic (ValuesAndExpressions::ProhibitCommaSeparatedStatements)
			'config' => { type => SCALAR, optional => 1, },
		}
	);
	$log->tracef('Entering get_config(%s)', \%params);
	my %config = ( map { $_ => undef } IRON_CONFIG_KEYS() ); ## preset config keys.
	lock_keys(%config, IRON_CONFIG_KEYS());
	_read_iron_config_file(\%config, File::Spec->catfile(File::HomeDir->my_home, '.iron.json')); # Homedir
	_read_iron_config_env_vars(\%config); # Global envs
	_read_iron_config_file(\%config, File::Spec->catfile(File::Spec->curdir(), 'iron.json')); # current dir
	if(defined $params{'config'}) { # config file specified when creating the class, if given.
		_read_iron_config_file(\%config,
				File::Spec->file_name_is_absolute($params{'config'})
				? $params{'config'} : File::Spec->catfile(File::Spec->curdir(), $params{'config'})
				);
	}
	# The parameters given when the object was created, except 'config'
	my @copy_param_keys = grep { !/^config$/msx} keys %params;
	@config{@copy_param_keys} = @params{@copy_param_keys};

	$log->tracef('Exiting get_config: %s', \%config);
	return \%config;
}

# Replace the existing values in $config if new environment variables found.
#	Vars:
#	$config->{'project_id'}  = $ENV{'IRON_PROJECT_ID'}
#	$config->{'token'}       = $ENV{'IRON_TOKEN'}
#	$config->{'host'}        = $ENV{'IRON_HOST'}
#	$config->{'protocol'}    = $ENV{'IRON_PROTOCOL'}
#	$config->{'port'}        = $ENV{'IRON_PORT'}
#	$config->{'api_version'} = $ENV{'IRON_API_VERSION'}
#	$config->{'host_path_prefix'} = $ENV{'IRON_HOST_PATH_PREFIX'}
#	$config->{'timeout'}     = $ENV{'IRON_TIMEOUT'}
sub _read_iron_config_env_vars {
	my ($config) = @_;
	$log->tracef('Entering _read_iron_config_env_vars(%s)', $config);
	foreach my $config_key (keys %{$config}) {
		if (defined $ENV{'IRON_' . uc $config_key}) {
			$config->{$config_key} = $ENV{'IRON_' . uc $config_key};
		}
	}
	$log->tracef('Exiting _read_iron_config_env_vars: %s', $config);
	return $config;
}


# Try to read the file given as second parameter. (if undef, fail).
# If fails, gracefully return 0; if succeed, change configuration (first parameter) and return 1.
sub _read_iron_config_file {
	my ($config, $full_path_name) = @_;
	$log->tracef('Entering _read_iron_config_file(%s, %s)', $full_path_name, $config);

	assert_nonblank( $full_path_name, 'full_path_name is not defined or is blank.' );

	my $read_config;
	my $rval;
	if( -e $full_path_name) {
		$log->tracef('File %s exists', $full_path_name);
		if(my $file_contents = File::Slurp::read_file($full_path_name)) {
			$log->tracef('Read file %s', $full_path_name);
			$read_config = JSON::decode_json($file_contents);
			foreach my $config_key (keys %{$config}) {
				if (defined $read_config->{$config_key}) {
					$config->{$config_key} = $read_config->{$config_key};
				}
			}
			$rval = 1;
		}
		else {
			$log->debugf('Could not read file %s', $full_path_name);
			$rval = 0;
		}
	}
	else {
		$log->tracef('File %s does not exist', $full_path_name);
		$rval = 0;
	}
	$log->tracef('Exiting _read_iron_config_file: %s', $config);
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

    perldoc IO::Iron


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

1; # End of IO::Iron::Common
