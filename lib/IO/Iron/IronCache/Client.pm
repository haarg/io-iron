package IO::Iron::IronCache::Client;

## no critic (Documentation::RequirePodAtEnd)
## no critic (Documentation::RequirePodSections)
## no critic (Subroutines::RequireArgUnpacking)

use 5.008_001;
use strict;
use warnings FATAL => 'all';

# Global creator
BEGIN {
	use parent qw( IO::Iron::ClientBase ); # Inheritance
}

# Global destructor
END {
}

=head1 NAME

IO::Iron::IronCache::Client - IronCache (Online Item-Value Storage) Client.

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';


=head1 SYNOPSIS

	require IO::Iron::IronCache::Client;
	require IO::Iron::IronCache::Item;
	my $ironcache_client = IO::Iron::IronCache::Client->new();
	# or
	use IO::Iron qw(get_ironcache);
	my $ironcache_client = get_ironcache();
	
	# Operate with caches.	
	my @iron_caches = $ironcache_client->get_caches();
	my $iron_cache = $ironcache_client->create_cache('name' => 'My_Iron_Cache');
	# Or get an existing cache.
	my $iron_cache = $ironcache_client->get_cache('name' => 'My_Iron_Cache');
	my $cache_deleted = $ironcache_client->delete_cache('name' => 'My_Iron_Cache');
	my $info = $ironcache_client->get_info_about_cache('name' => 'My_Iron_Cache');
	
	# Operate with items.
	my $iron_cache_item_put = IO::Iron::IronCache::Item->new(
		'value' => "10",
		'expires_in' => 60, # Expires in 60 seconds.
		#'replace' => 1, # Only set the item if the item is already in the cache.
		#'add' => 1 # Only set the item if the item is not already in the cache.
		#'cas' => '12345' # Only set the item if there is already an item with matching key and cas.
		);
	my $item_put_ok = $iron_cache->put('key' => 'my_item', 'item' => $iron_cache_item_put);
	my $item_put_new_value = $iron_cache->increment('key' => 'my_item', 'increment' => 15);
	my $iron_cache_item_get = $iron_cache->get('key' => 'my_item');
	my $item_deleted_ok = $iron_cache->delete('key' => 'my_item');
	my $items_cleared_ok = $iron_cache->clear();


=head1 REQUIREMENTS

See L<IO::Iron|IO::Iron> for requirements.

=cut

use Log::Any  qw{$log};
use Hash::Util qw{lock_keys lock_keys_plus unlock_keys legal_keys};
use Carp::Assert::More;
use English '-no_match_vars';
use Params::Validate qw(:all);

use IO::Iron::IronCache::Api ();
use IO::Iron::Common ();
require IO::Iron::Connection;
require IO::Iron::IronCache::Cache;

# CONSTANTS for this package

# DEFAULTS


=head1 DESCRIPTION

IO::Iron::IronCache is a client for the IronCache online key-value store at L<http://www.iron.io/|http://www.iron.io/>.
IronCache is a cloud based key-value store with a REST API.
IO::Iron::IronCache::Client creates a Perl object for interacting with IronCache.
All IronCache functions are available.

The class IO::Iron::IronCache::Client instantiates the 'project', IronCache access configuration.

=head2 IronCache Key-Value Store

L<http://www.iron.io/|http://www.iron.io/>

IronCache is a key-value store online, usable on the principle of 
"Software as a Service", i.e. SaaS. It is available to Internet connecting 
applications via its REST interface. Built with distributed 
cloud applications in mind, it provides on-demand key-value storage,
value persistance/expiry as requested and cloud-optimized performance.
[see L<http://www.iron.io/|http://www.iron.io/>]

=head2 Using the IronCache Client Library

IO::Iron::IronCache::Client is a normal Perl package meant to be used as an object.

	require IO::Iron::IronCache::Client;
	my $iron_cache_client = IO::Iron::IronCache::Client->new();

Please see L<IO::Iron|IO::Iron> for further parameters and general usage.

After creating the client, the client can create a new cache (storage), get or 
delete an old one or get all the existing caches within 
the same project.

The client has all the methods which interact with 
the caches; the cache (object of class IO::Iron::IronCache::Cache) 
has methods which involve items inside the cache.

When failed to do the requested action, the methods return an exception 
using Perl package Exception::Class. Calling program should trap these 
with e.g. Perl package Try::Tiny.

	# Create the cache client.
	require IO::Iron::IronCache::Client;
	my $ironcache_client = IO::Iron::IronCache::Client->new();
	# Or
	$ironcache_client = IO::Iron::IronCache::Client->new(
		config => 'iron_cache.json
		);
	
	# Operate with caches.
	# Get all the existing caches as objects of 
	# class IO::Iron::IronCache::Cache.
	my @iron_caches = $ironcache_client->get_caches();
	
	# Create a new cache object by its name.
	# Returns object of class IO::Iron::IronCache::Cache.
	my $iron_cache = $ironcache_client->create_cache('name' => 'My_Iron_Cache');
	# Or get an existing cache.
	$iron_cache = $ironcache_client->get_cache('name' => 'My_Iron_Cache');
	
	# Delete a cache by its name. Return 1 for success.
	my $cache_deleted = $ironcache_client->delete_cache('name' => 'My_Iron_Cache');
	
	# Get info about a cache.
	my $info_hash = $ironcache_client->get_info_about_cache('name' => 'My_Iron_Cache');
	
	# Operate with items.
	# Create an item.
	my $iron_cache_item_put = IO::Iron::IronCache::Item->new(
		'value' => "10",
		'expires_in' => 60, # Expires in 60 seconds.
		#'replace' => 1, # Only set the item if the item is already in the cache.
		#'add' => 1, # Only set the item if the item is not already in the cache.
		#'cas' => '12345', # Only set the item if there is already an item with matching key and cas.
		);
	my $item_put = $iron_cache->put('key' => 'my_item_key', 'item' => $iron_cache_item_put);
	my $item_put_new_value = $iron_cache->increment('key' => 'my_item_key', 'increment' => 15);
	my $iron_cache_item_get = $iron_cache->get('key' => 'my_item_key');
	my $item_deleted = $iron_cache->delete('key' => 'my_item_key');

	# Empty the cache (delete all items inside). Return 1 for success.
	my $items_cleared_ok = $iron_cache->clear();

An IO::Iron::IronCache::Cache object gives access to a single cache.
With it you can do all the normal things one would with a key-value store.

Items are objects of the class IO::Iron::IronCache::Item. It contains 
the following attributes:

=over 8

=item - value, Free text. Will be JSONized. If you need an object serialized, don't use JSON. Use e.g. YAML. Then give the resulting string here.

=item - expires_in, How long in seconds to keep the item in the cache before it is deleted. By default, items do not expire. Maximum is 2,592,000 seconds (30 days).

=item - replace, If set to true, only set the item if the item is already in the cache. If the item is not in the cache, do not create it.

=item - add, If set to true, only set the item if the item is not already in the cache. If the item is in the cache, do not overwrite it.

=item - cas: If set, the new item will only be placed in the cache if there is an existing item with a matching key and cas value. An item's cas value is automatically generated and is included when the item is retrieved.

-item - N.B. The item key is not stored in the object.

=back

Cas value changes every time the item value is updated to cache.
It can be used to verify that the value has not been changed since the 
last get operation.

	$iron_cache_item_key = 'my_item_key';
	my $iron_cache_item_put_1 = IO::Iron::IronCache::Item->new(
		'value' => "10",
		'expires_in' => 60, # Expires in 60 seconds.
		'replace' => 1,
		);
	# Or
	my $iron_cache_item_put_2 = IO::Iron::IronCache::Item->new(
		'value' => "10",
		'expires_in' => 60, # Expires in 60 seconds.
		'add' => 1,
		);

IO::Iron::IronCache::Cache objects are created by the client 
(object of IO::Iron::IronCache::Client) or they can be created by the user.
If an item is put to a cache which doesn't exist yet, 
IronCache creates a new cache automatically.

While it is possible
to create a cache object from IO::Iron::IronCache::Cache, user should not
normally do this. When the cache object is created 
by the Client, it gets the Client's REST connection parameters.
Otherwise these will need to be set manually.

With an IO::Iron::IronCache::Cache object you can put items to the cache, 
or get existing items from it.

Get cache id. Not really needed for anything.
Just internal reference for Iron Cache.

	my $cache_id = $iron_cache->id();

Get cache name.

	my $cache_name = $iron_cache->name();

Put an item into the cache. Returns 1 if successful.

	my $item_put = $iron_cache->put('key' => $iron_cache_item_key, 'item' => $iron_cache_item_put);

If the item is an integer value, you can simply increment it by another 
value. If the value is negative, the value in the cache will be 
decreased. Returns the new value.

	my $item_put_new_value = $iron_cache->increment('key' => $iron_cache_item_key, 'increment' => 15);

Get an item from the cache by its name. Returns an object of the class 
IO::Iron::IronCache::Item if successful.

	my $iron_cache_item_get = $iron_cache->get('key' => $iron_cache_item_key);

Delete an item in the cache by its name. Returns 1 if successful.

	my $item_deleted_ok = $iron_cache->delete('key' => $iron_cache_item_key);

Clear the cache (delete all items inside). Return 1 for success.

	my $items_cleared_ok = $iron_cache->clear();

=head3 Exceptions

A REST call to Iron service may fail for several reason.
All failures generate an exception using the L<Exception::Class|Exception::Class> package.
Class IronHTTPCallException contains the field status_code, response_message and error.
Error is formatted as such: IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>.

	use Try::Tiny;
	use Scalar::Util qw{blessed};
	try {
		my $queried_iron_cache_01 = $iron_cache_client->get_cache('name' => 'unique_cache_name_01');
	}
	catch {
		die $_ unless blessed $_ && $_->can('rethrow');
		if ( $_->isa('IronHTTPCallException') ) {
			if ($_->status_code == 404) {
				print "Bad things! Can not just find the catch in this!\n";
			}
		}
		else {
			$_->rethrow; # Push the error upwards.
		}
	};


=head1 SUBROUTINES/METHODS

=head2 new

Creator function.

=cut

sub new {
	my $class = shift;
	my %params = validate(
		@_, {
			map { $_ => { type => SCALAR, optional => 1 }, } IO::Iron::Common::IRON_CLIENT_PARAMETERS(), ## no critic (ValuesAndExpressions::ProhibitCommaSeparatedStatements)
		}
	);

	$log->tracef('Entering new(%s, %s)', $class, %params);
	my $self = IO::Iron::ClientBase->new();
	# Add more keys to the self hash.
	my @self_keys = (
			'caches',        # References to all objects created of class IO::Iron::IronCache::Cache. Not in use!
			legal_keys(%{$self}),
	);
	unlock_keys(%{$self});
	lock_keys_plus(%{$self}, @self_keys);
	my $config = IO::Iron::Common::get_config(%params);
	$log->debugf('The config: %s', $config);
	$self->{'project_id'} = defined $config->{'project_id'} ? $config->{'project_id'} : undef;
	my @caches;
	$self->{'caches'} = [];
	assert_nonblank( $self->{'project_id'}, 'self->{project_id} is not defined or is blank');

	unlock_keys(%{$self});
	bless $self, $class;
	lock_keys(%{$self}, @self_keys);

	# Set up the connection client
	my $connection = IO::Iron::Connection->new( {
		'project_id' => $config->{'project_id'},
		'token' => $config->{'token'},
		'host' => $config->{'host'},
		'protocol' => $config->{'protocol'},
		'port' => $config->{'port'},
		'api_version' => $config->{'api_version'},
		'host_path_prefix' => $config->{'host_path_prefix'},
		'timeout' => $config->{'timeout'},
		'connector' => $params{'connector'},
		}
	);
	$self->{'connection'} = $connection;
	$log->debugf('IronCache client created with config: (project_id=%s; token=%s; host=%s; timeout=%s).', $config->{'project_id'}, $config->{'token'}, $config->{'host'}, $config->{'timeout'});
	$log->tracef('Exiting new: %s', $self);
	return $self;
}

=head2 get_caches

Return objects of class IO::Iron::IronCache::Cache representing all the caches 
within this project.

=over 8

=item Params: [None]

=item Return: List of IO::Iron::IronCache::Cache objects.

=back

=cut

sub get_caches {
	my $self = shift;
	my %params = validate(
		@_, {
			# No parameters
		}
	);
	$log->tracef('Entering get_caches()');

	my @caches;
	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronCache::Api::IRONCACHE_LIST_CACHES(), { } );
	$self->{'last_http_status_code'} = $http_status_code;
	foreach my $cache_info (@{$response_message}) {
		my $get_cache_name = $cache_info->{'name'};
		my $cache = IO::Iron::IronCache::Cache->new({
			'ironcache_client' => $self, # Pass a reference to the parent object.
			'name' => $get_cache_name,
			'connection' => $self->{'connection'},
		});
		push @caches, $cache;
	}
	#push @{$self->{'caches'}}, @caches; # Store only created caches!
	$log->debugf('Created caches: %s', \@caches);

	$log->tracef('Exiting get_caches: %s', \@caches);
	return @caches;
}

=head2 get_info_about_cache

=over 8

=item Params: cache name.

=item Return: a hash containing info about cache.

=back

=cut

sub get_info_about_cache {
	my $self = shift;
	my %params = validate(
		@_, {
			'name' => { type => SCALAR, }, # cache name.
		}
	);
	$log->tracef('Entering get_info_about_cache(%s)', \%params);

	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronCache::Api::IRONCACHE_GET_INFO_ABOUT_A_CACHE(),
			{ '{Cache Name}' => $params{'name'}, }
		);
	$self->{'last_http_status_code'} = $http_status_code;
	my $info = $response_message;

	# info:
	# {'id':'523566104a734c39bf00041e','project_id':'51bdf5fb2267d84ced002c99',
	# 'name':'TEST_CACHE_01','size':0,'data_size':0}
	$log->tracef('Exiting get_info_about_cache: %s', $info);
	return $info;
}

=head2 get_cache

Return a IO::Iron::IronCache::Cache object representing
a particular key-value cache. The cache object is linked to the
creating IO::Iron::IronCache::Client object.

=over 8

=item Params: cache name. Cache must exist. If not, fails with an exception.

=item Return: IO::Iron::IronCache::Cache object.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub get_cache {
	my $self = shift;
	my %params = validate(
		@_, {
			'name' => { type => SCALAR, }, # cache name.
		}
	);
	$log->tracef('Entering get_cache(%s)', \%params);

	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronCache::Api::IRONCACHE_GET_INFO_ABOUT_A_CACHE(),
			{ '{Cache Name}' => $params{'name'}, }
		);
	$self->{'last_http_status_code'} = $http_status_code;
	my $get_cache_name = $response_message->{'name'};
	my $cache = IO::Iron::IronCache::Cache->new({
		'ironcache_client' => $self, # Pass a reference to the parent object.
		'name' => $get_cache_name,
		'connection' => $self->{'connection'},
	});
	push @{$self->{'caches'}}, $cache;
	$log->debugf('Created a new IO::Iron::IronCache::Cache object (name=%s).', $get_cache_name);
	$log->tracef('Exiting get_cache: %s', $cache);
	return $cache;
}

=head2 create_cache

Return a IO::Iron::IronCache::Cache object representing
a particular message cache. This call doesn't actually 
access IronCache API because, if an item is put to a 
cache which doesn't exist yet, IronCache creates a new cache 
automatically. create_cache only creates 
a new IO::Iron::IronCache::Cache object which is linked to the
creating IO::Iron::IronCache::Client object.

=over 8

=item Params: cache name.

=item Return: IO::Iron::IronCache::Cache object.

=back

=cut

sub create_cache {
	my $self = shift;
	my %params = validate(
		@_, {
			'name' => { type => SCALAR, }, # cache name.
		}
	);
	$log->tracef('Entering create_cache(%s)', \%params);

	my $cache = IO::Iron::IronCache::Cache->new({
		'ironcache_client' => $self, # Pass a reference to the parent object.
		'name' => $params{'name'},
		'connection' => $self->{'connection'},
	});
	push @{$self->{'caches'}}, $cache;

	$log->debugf('Created a new IO::Iron::IronCache::Cache object (name=%s.)', $params{'name'});
	$log->tracef('Exiting get_cache: %s', $cache);
	return $cache;
}

=head2 delete_cache

Delete an IronCache cache.

=over 8

=item Params: cache name. Cache must exist. If not, fails with an exception.

=item Return: 1 == success.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub delete_cache {
	my $self = shift;
	my %params = validate(
		@_, {
			'name' => { type => SCALAR, }, # cache name.
		}
	);
	$log->tracef('Entering delete_cache(%s)', \%params);

	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronCache::Api::IRONCACHE_DELETE_A_CACHE(),
			{
				'{Cache Name}' => $params{'name'},
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;
	@{$self->{'caches'}} = grep { $_->name() ne $params{'name'} } @{$self->{'caches'}};

	$log->debugf('Deleted cache (name=%s.)', $params{'name'});
	$log->tracef('Exiting delete_cache: %d', 1);
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

1; # End of IO::Iron::IronCache::Client
