package IO::Iron::IronMQ::Client;

## no critic (Documentation::RequirePodAtEnd)
## no critic (Documentation::RequirePodSections)

use 5.010_000;
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

IO::Iron::IronMQ::Client - IronMQ (Message Queue) Client.

=cut

# VERSION: generated by DZP::OurPkgVersion


=head1 SYNOPSIS

    require IO::Iron::IronMQ::Client;

    my $iron_mq_client = IO::Iron::IronMQ::Client->new( {} );
    my $iron_mq_queue = $iron_mq_client->create_queue('My_Message_Queue');
    # Or get an existing queue.
    my $iron_mq_queue = $iron_mq_client->get_queue('My_Message_Queue');
    my $queue_info = $iron_mq_client->get_info_about_queue('My_Message_Queue');
    my $iron_mq_msg_send = IO::Iron::IronMQ::Message->new( {
        'body' => "My message",
        } );
    my $msg_send_id = $iron_mq_queue->push($iron_mq_msg_send);
    my $iron_mq_msg_peek = $iron_mq_queue->peek();
    my @iron_mq_msgs_pull = $iron_mq_queue->pull( { n => 1 } );
    my $pulled_msg_body = $iron_mq_msgs_pull[0]->body();
    my $delete_ret = $iron_mq_queue->delete( $iron_mq_msgs_pull[0]->id() );
    my $cleared = $iron_mq_queue->clear;
    my $queue_deleted = $iron_mq_client->delete_queue('My_Message_Queue');

=head1 REQUIREMENTS

Requires the following packages:

=over 8

=item Log::Any, v. 0.15

=item File::Slurp, v. 9999.19

=item JSON, v. 2.53

=item Carp::Assert::More, v. 1.12

=item REST::Client, v. 88

=item File::HomeDir, v. 1.00,

=item Exception::Class, v. 1.37

=item Try::Tiny, v. 0.18

=item Scalar::Util, v. 1.27

=back

Requires IronMQ account. Three configuration items must be set (others available) before using the functions: 'project_id', 'token' and 'host'.
These can be set in a json file, as environmental variables or as parameters when creating the object.

=over 8

=item project_id, the identification string, from IronMQ.

=item token, an OAuth authentication token string, from IronMQ.

=item host, the cloud in which you want to operate: 'mq-aws-us-east-1.iron.io/1' for AWS (Amazon)
 or 'mq-rackspace-ord.iron.io/1' for Rackspace.

=back

=cut

use File::Slurp qw{read_file};
use Log::Any  qw{$log};
use File::Spec qw{read_file};
use File::HomeDir;
use Hash::Util 0.06 qw{lock_keys lock_keys_plus unlock_keys legal_keys};
use Carp::Assert;
use Carp::Assert::More;
use English '-no_match_vars';
use Params::Validate qw(:all);


use IO::Iron::IronMQ::Api;
use IO::Iron::Common;
require IO::Iron::Connection;
require IO::Iron::IronMQ::Queue;

# CONSTANTS for this package

# DEFAULTS


=head1 DESCRIPTION

IO::Iron::IronMQ is a client for the IronMQ message queue at L<http://www.iron.io/|http://www.iron.io/>.
IronMQ is a cloud based message queue with a REST API.
IO::Iron::IronMQ creates a Perl object for interacting with IronMQ.
All IronMQ functions are available.

The class IO::Iron::IronMQ::Client instantiates the 'project', IronMQ access configuration.

=head2 IronMQ Message Queue

L<http://www.iron.io/|http://www.iron.io/>

IronMQ is a message queue as a service available to Internet connecting 
applications via its REST interface. Built with distributed 
cloud applications in mind, it provides on-demand message 
queuing with HTTPS transport, one-time FIFO delivery, message persistence, 
and cloud-optimized performance. [see L<http://www.iron.io/|http://www.iron.io/>]

=head2 Using the IronMQ Client Library

IO::Iron::IronMQ::Client is a normal Perl package meant to be used as an object.

    require IO::Iron::IronMQ::Client;
    my $iron_mq_client = IO::Iron::IronMQ::Client->new( { } );

The following parameters can be given to new() as items in the first parameter which is a hash.

=over 8

=item project_id,        The ID of the project to use for requests.

=item token,             The OAuth token that is used to authenticate requests.

=item host,              The domain name the API can be located at. E.g. 'mq-aws-us-east-1.iron.io/1'.

=item protocol,          The protocol that will be used to communicate with the API. Defaults to "https".

=item port,              The port to connect to the API through. Defaults to 443.

=item api_version,       The version of the API to connect through. Defaults to the version supported by the client.

=item host_path_prefix,  Path prefix to the RESTful url. Defaults to '/1'. Used with non-standard clouds/emergency service back up addresses.

=item timeout,           REST client timeout (for REST calls accessing IronMQ.)

=item config,            Config filename with path if required.

=back

You can also give the parameters in the config file '.iron.json'
(in home dir) or 
'iron.json' (in current dir) or as environmental variables. Please read 
L<http://dev.iron.io/mq/reference/configuration/|http://dev.iron.io/mq/reference/configuration/>
for further details.

After creating the client, the client can create a new message queue, get, 
modify or delete an old one or get all the existing message queues within 
the same project.

The client has all the methods which interact with 
queues; the queue (object of IO::Iron::IronMQ::Queue) has methods which involve 
messages.

If failed, the methods cause exception. After successfull REST API call, 
the HTTP return code can be retrieved with method
last_http_status_code().

    # Create a new queue. (Parameter queue name;
    # return an IO::Iron::IronMQ::Queue object)
    my $iron_mq_queue = $iron_mq_client->create_queue(name => 'My_Message_Queue',
			'subscribers' => [
				{ "url" => "ironmq:///Other_queue_name" },
			],
			'push_type' => 'unicast',
			'retries' => 0,
			'retries_delay' => 3,
			'error_queue' => "Error_queue_name",
    );

    # Get an existing queue. (Parameter queue name;
    # return an IO::Iron::IronMQ::Queue object)
    my $iron_mq_queue = $iron_mq_client->get_queue( 'name' => 'My_Message_Queue');

    # Delete an existing queue. (Parameter queue name;
    # return 1)
    my $success = $iron_mq_client->delete_queue( 'name' => 'My_Message_Queue');

    # Get all the queues. 
    # Return a list of IO::Iron::IronMQ::Queue objects.
    my @iron_mq_queues = $iron_mq_client->get_queues();

    # Update a queue. Return a IO::Iron::IronMQ::Queue object. 
    # Queue properties: set queue type (pull, multicast, unicast), set subscribers.
	my $push_from_queue = $iron_mq_client->update_queue(
			'name' => 'My_Message_Queue',
			'subscribers' => [
				{ "url" => "ironmq:///Other_queue_name" },
			],
			'push_type' => 'unicast',
			'retries' => 0,
			'retries_delay' => 3,
			'error_queue' => "Error_queue_name",
		);

    # Get info about the queue
    # (Return a hash containing items name, id, size, project, etc.).
    my $queue_info = $iron_mq_client->get_info_about_queue( 'name' => 'My_Message_Queue');

A IO::Iron::IronMQ::Queue object gives access to a single message queue.
With it you can do all the normal things one would with a message queue.

Messages are objects of the class IO::Iron::IronMQ::Message. It contains 
the following attributes:

=over 8

=item - body, Free text. Will be JSONized. If you need an object serialized, don't use JSON. Use e.g. YAML. Then give the resulting string here.

=item - timeout, When reading from queue, after timeout (in seconds), item will be placed back onto queue.

=item - delay, The item will not be available on the queue until this many seconds have passed.

=item - expires_in, How long in seconds to keep the item on the queue before it is deleted.

=item - id, Message id from IronMQ (available after message has been pulled/peeked).

=item - reserved_count, Not yet implemented. (available after message has been pulled/peeked).

=item - push_status, Not yet implemented. (available after message has been pulled/peeked).

=back

	my $iron_mq_msg_send_01 = IO::Iron::IronMQ::Message->new(
			'body' => "My message",
			);
	# Or
	use YAML::Tiny;
	%msg_body_hash_02 = (msg_body_text => 'My message 2', msg_body_item => {sub_item => 'Sub text'});
	my $yaml = YAML::Tiny->new(); $yaml->[0] = \%msg_body_hash_02;
	my $msg_body = $yaml->write_string();
	my $iron_mq_msg_send_02 = IO::Iron::IronMQ::Message->new(
			'body' => $msg_body,
			'timeout' => $msg_timeout, # When reading from queue, after timeout (in seconds), item will be placed back onto queue.
			'delay' => $msg_delay,	 # The item will not be available on the queue until this many seconds have passed.
			'expires_in' => $msg_expires_in, # How long in seconds to keep the item on the queue before it is deleted.
			);
	# Return YAML serialized structure:
	my $yaml_de = YAML::Tiny->new(); $yaml_de = $yaml_de->read_string($iron_mq_msg_send_02->body());

IO::Iron::IronMQ::Queue objects are created by the client IO::Iron::IronMQ::Client.
With an IO::Iron::IronMQ::Queue object you can push messages to the queue, 
or pull messages from it. The names push and pull are used because the 
queue is likened to a pipe. The queue is like a FIFO pipe (first in, first out).

Get queue id.

	my $queue_id = $iron_mq_queue->id();

Get queue name.

	my $queue_name = $iron_mq_queue->name();

Add one or more messages to the queue. Returns the ids of the messages sent
or the number of sent messages.

	my $msg_send_id = $iron_mq_queue->push( 'messages' => [ $iron_mq_msg_send_01 ] );
	my @msg_send_ids = $iron_mq_queue->push( 'messages' => [ $iron_mq_msg_send_01, $iron_mq_msg_send_02 ] );
	my $number_of_msgs_sent = $iron_mq_queue->push( 'messages' => [ $iron_mq_msg_send_01, $iron_mq_msg_send_02 ] );

Read one or more messages from the queue and reserve them so another process
cannot access them. Parameters: n (number of messages you want, default 1, 
maximum 100; if there is less, all available messages will be returned), 
if no messages, an empty list will be returned,
timeout (After timeout (in seconds), item will be placed back onto queue, 
default is 60 seconds, minimum is 30 seconds, and maximum is 86,400 seconds (24 hours)).

	my @iron_mq_msg_pulls = $iron_mq_queue->pull( n => 10, timeout => 120 );

Read one or more messages from the queue but don't reserve them.
Parameters: n (number of messages you want, default 1, maximum 100; if there 
is less, all available messages will be returned),
if no messages, an empty list will be returned.

	my @iron_mq_msg_peeks = $iron_mq_queue->peek( n => 10 );

Delete one or more messages from the queue. Call this when you have 
processed the messages. Returns the ids of the messages deleted
or the number of deleted messages.

	my $deleted_msg_id = $iron_mq_queue->delete( 'ids' => [ $msg_id_01 ] );
	my @deleted_msg_ids = $iron_mq_queue->delete( 'ids' => [ $msg_id_01, $msg_id_02 ] );
	my $number_of_msgs_deleted = $iron_mq_queue->delete( 'ids' => [ $msg_id_01, $msg_id_02 ] );

Release one or more messages back to the queue.
Releasing a reserved message unreserves the message and puts 
it back on the queue as if the message had timed out.
Delay: The item will not be available on the queue until this 
many seconds have passed. Default is 0 seconds.
Maximum is 604,800 seconds (7 days).

Returns 1.

	my $released_msg = $iron_mq_queue->release( 'id' => $msg_id_01, 'delay' => $delay );

Touch one or more messages in the queue. Touching a reserved message extends 
its timeout to the duration specified when the message was created. 
Default is 60 seconds.
Returns 1.

	my $touched_msg = $iron_mq_queue->touch( 'id' => $msg_id_01 );

Clear all messages from the queue: delete all messages, 
whether they are reserved or not.

	my $cleared = $iron_mq_queue->clear();

Get queue size.

	my $size = $iron_mq_queue->size();

Get push status for a message. Retrieve the push status for a 
particular message which will let you know which subscribers 
have received the message, which have failed, how many times 
it's tried to be delivered and the status code returned from 
the endpoint.

	my $info = $iron_mq_queue->get_push_status( 'id' => $msg_id );
	my @subscribers = (@{info->{'subscribers'}});

Acknowledge / Delete Push Message for a Subscriber. 
This is only for use with long running processes that have 
previously returned a 202.

	my $info = $iron_mq_queue->get_push_status( 'id' => $msg_id );
	my @subscribers = (@{info->{'subscribers'}});
	my $push_acknowledged = $iron_mq_queue->delete_push_message(
		'id' => $msg_id, 'subscriber' => $subscribers[0]->{'id'}
		);

Add Subscribers to a Queue.

	my $add_ret_val = $iron_mq_queue->add_subscribers(
			'name' => $queue_name,
			'subscribers' => [
				{ 'url' => "ironmq://project_id:token\@host/queue_name" },
				{ 'url' => "ironmq:///$queue_name_02" },
			],
		);

Remove Subscribers from a Queue

	my $del_ret_val = $iron_mq_client->delete_subscribers(
			'name' => $queue_name,
			'subscribers' => [
				{ 'url' => "ironmq:///$queue_name" },
			],
		);

=head3 Exceptions

A REST call to IronMQ server may fail for several reason.
All failures generate an exception using the L<Exception::Class|Exception::Class> package.
Class IronHTTPCallException contains the field status_code, response_message and error.
Error is formatted as such: IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>.

	use Try::Tiny;
	use Scalar::Util qw{blessed};
	try {
		my $queried_iron_mq_queue_01 = $iron_mq_client->get_queue($unique_queue_name_01);
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
			'queues',        # References to all objects created of class IO::Iron::IronMQ::Queue.
			legal_keys(%{$self}),
	);
	unlock_keys(%{$self});
	lock_keys_plus(%{$self}, @self_keys);
	my $config = IO::Iron::Common::get_config(%params);
	$log->debugf('The config: %s', $config);
	$self->{'project_id'} = defined $config->{'project_id'} ? $config->{'project_id'} : undef;
	$self->{'queues'} = [];
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
	$log->debugf('IronMQ Connection created with config: (project_id=%s; token=%s; host=%s; timeout=%s).', $config->{'project_id'}, $config->{'token'}, $config->{'host'}, $config->{'timeout'});
	$log->tracef('Exiting new: %s', $self);
	return $self;
}

=head2 get_queue

Return a IO::Iron::IronMQ::Queue object representing
a particular message queue.

=over 8

=item Params: queue name. Queue must exist. If not, fails with an exception.

=item Return: IO::Iron::IronMQ::Queue object.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub get_queue {
	my $self = shift;
	my %params = validate(
		@_, {
			'name' => { type => SCALAR, }, # queue name.
		}
	);
	$log->tracef('Entering get_queue(%s)', \%params);
	assert_nonblank( $params{'name'}, 'Parameter \'name\' is a non blank string');

	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronMQ::Api::IRONMQ_GET_INFO_ABOUT_A_MESSAGE_QUEUE(),
			{ '{Queue Name}' => $params{'name'}, }
		);
	$self->{'last_http_status_code'} = $http_status_code;
	my $get_queue_id = $response_message->{'id'};
	my $get_queue_name = $response_message->{'name'};
	my $queue = IO::Iron::IronMQ::Queue->new({
		'ironmq_client' => $self, # Pass a reference to the parent object.
		'id' => $get_queue_id,
		'name' => $get_queue_name,
		'connection' => $connection,
	});
	$log->debugf('Created a new IO::Iron::IronMQ::Queue object (queue id=%s; name=%s.', $get_queue_id, $get_queue_name);
	$log->tracef('Exiting get_queue: %s', $queue);
	return $queue;
}

=head2 create_queue

Return a IO::Iron::IronMQ::Queue object representing
a particular message queue.

URL format for subscribers to Iron.io systems:
[ironmq_or_ironworker]://[project_id:token]@[host]/queue_or_worker_name

=over 8

=item Params: name, subscribers, push_type, retries, retries_delay, error_queue.

=item Return: IO::Iron::IronMQ::Queue object.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub create_queue {
	my $self = shift;
	my %params = validate(
		@_, {
			'name' => { type => SCALAR, callbacks => {
                    'RFC 3986 reserved character check' => sub { return ! IO::Iron::Common::contains_rfc_3986_res_chars(shift) },
                }}, # queue name.
			'subscribers' => { type => ARRAYREF, optional => 1 }, # array of subscriber hashes containing a required "url" field and an optional "headers" map for custom headers.
			'push_type' => { type => SCALAR, optional => 1 }, # Either multicast to push to all subscribers or unicast to push to one and only one subscriber. Default is multicast.
			'retries' => { type => SCALAR, optional => 1 }, # retries: How many times to retry on failure. Default is 3. Maximum is 100.
			'retries_delay' => { type => SCALAR, optional => 1 }, # retries_delay: Delay between each retry in seconds. Default is 60.
			'error_queue' => { type => SCALAR, optional => 1 }, # error_queue: The name of another queue where information about messages that can't be delivered will be placed.
		}
	);
	$log->tracef('Entering create_queue(%s)', \%params);
	assert_nonblank( $params{'name'}, 'Parameter \'name\' is a non blank string');

	my $connection = $self->{'connection'};
	my %item_body;
	$item_body{'subscribers'} = $params{'subscribers'} if ($params{'subscribers'});
	$item_body{'push_type'} = $params{'push_type'} if ($params{'push_type'});
	$item_body{'retries'} = $params{'retries'} if ($params{'retries'});
	$item_body{'retries_delay'} = $params{'retries_delay'} if ($params{'retries_delay'});
	$item_body{'error_queue'} = $params{'error_queue'} if ($params{'error_queue'});
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronMQ::Api::IRONMQ_UPDATE_A_MESSAGE_QUEUE(),
			{
				'{Queue Name}' => $params{'name'},
				'body'         => \%item_body,
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;
	my $get_queue_id = $response_message->{'id'};
	my $get_queue_name = $response_message->{'name'};
	my $queue = IO::Iron::IronMQ::Queue->new({
		'ironmq_client' => $self, # Pass a reference to the parent object.
		'connection' => $connection,
		'id' => $get_queue_id,
		'name' => $get_queue_name,
	});
	$log->debugf('Created a new IO::Iron::IronMQ::Queue object (queue id=%s; queue name=%s).', $get_queue_id, $get_queue_name);
	$log->tracef('Exiting create_queue: %s', $queue);
	return $queue;
}

=head2 update_queue

Return a IO::Iron::IronMQ::Queue object representing
a particular message queue.

=over 8

=item Params: name, subscribers, push_type, retries, retries_delay, error_queue.

=item Return: IO::Iron::IronMQ::Queue object.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub update_queue {
	my $self = shift;
	my %params = validate(
		@_, {
			'name' => { type => SCALAR, callbacks => {
                    'RFC 3986 reserved character check' => sub { return ! IO::Iron::Common::contains_rfc_3986_res_chars(shift) },
                }}, # queue name.
			'subscribers' => { type => ARRAYREF, optional => 1 }, # array of subscriber hashes containing a required "url" field and an optional "headers" map for custom headers.
			'push_type' => { type => SCALAR, optional => 1 }, # Either multicast to push to all subscribers or unicast to push to one and only one subscriber. Default is multicast.
			'retries' => { type => SCALAR, optional => 1 }, # retries: How many times to retry on failure. Default is 3. Maximum is 100.
			'retries_delay' => { type => SCALAR, optional => 1 }, # retries_delay: Delay between each retry in seconds. Default is 60.
			'error_queue' => { type => SCALAR, optional => 1 }, # error_queue: The name of another queue where information about messages that can't be delivered will be placed.
		}
	);
	$log->tracef('Entering update_queue(%s)', \%params);
	assert_nonblank( $params{'name'}, 'Parameter \'name\' is a non blank string');

	my $connection = $self->{'connection'};
	my %item_body;
	$item_body{'subscribers'} = $params{'subscribers'} if ($params{'subscribers'});
	$item_body{'push_type'} = $params{'push_type'} if ($params{'push_type'});
	$item_body{'retries'} = $params{'retries'} if ($params{'retries'});
	$item_body{'retries_delay'} = $params{'retries_delay'} if ($params{'retries_delay'});
	$item_body{'error_queue'} = $params{'error_queue'} if ($params{'error_queue'});
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronMQ::Api::IRONMQ_UPDATE_A_MESSAGE_QUEUE(),
			{
				'{Queue Name}' => $params{'name'},
				'body'         => \%item_body,
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;
	my $get_queue_id = $response_message->{'id'};
	my $get_queue_name = $response_message->{'name'};
	my $queue = IO::Iron::IronMQ::Queue->new({
		'ironmq_client' => $self, # Pass a reference to the parent object.
		'connection' => $connection,
		'id' => $get_queue_id,
		'name' => $get_queue_name,
	});
	$log->debugf('Created a new IO::Iron::IronMQ::Queue object (queue id=%s; queue name=%s).', $get_queue_id, $get_queue_name);
	$log->tracef('Exiting update_queue: %s', $queue);
	return $queue;
}

=head2 add_subscribers

Add subscribers to a push queue.

=over 8

=item Params: name, subscribers.

=item Returns 1 if succcessful

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub add_subscribers {
	my $self = shift;
	my %params = validate(
		@_, {
			'name' => { type => SCALAR, }, # queue name.
			'subscribers' => { type => ARRAYREF, optional => 1 }, # array of subscriber hashes containing a required "url" field and an optional "headers" map for custom headers.
		}
	);
	$log->tracef('Entering add_subscribers(%s)', \%params);
	assert_nonblank( $params{'name'}, 'Parameter \'name\' is a non blank string');

	my $connection = $self->{'connection'};
	my %item_body;
	$item_body{'subscribers'} = $params{'subscribers'} if ($params{'subscribers'});
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronMQ::Api::IRONMQ_ADD_SUBSCRIBERS_TO_A_MESSAGE_QUEUE(),
			{
				'{Queue Name}' => $params{'name'},
				'body'         => \%item_body,
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;

	$log->tracef('Exiting add_subscribers: %d', 1);
	return 1;
}

=head2 delete_subscribers

Delete the given subscribers from the queue.

=over 8

=item Params: name, subscribers.

=item 1

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

# TODO Inform bug in documentation: does not return the queue info, returns: "{msg => 'Updated'}".

sub delete_subscribers {
	my $self = shift;
	my %params = validate(
		@_, {
			'name' => { type => SCALAR, }, # queue name.
			'subscribers' => { type => ARRAYREF, optional => 1 }, # array of subscriber hashes containing a required "url" field and an optional "headers" map for custom headers.
		}
	);
	$log->tracef('Entering delete_subscribers(%s)', \%params);
	assert_nonblank( $params{'name'}, 'Parameter \'name\' is a non blank string');

	my $connection = $self->{'connection'};
	my %item_body;
	$item_body{'subscribers'} = $params{'subscribers'} if ($params{'subscribers'});
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronMQ::Api::IRONMQ_DELETE_SUBSCRIBERS_FROM_A_MESSAGE_QUEUE(),
			{
				'{Queue Name}' => $params{'name'},
				'body'         => \%item_body,
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;

	$log->debugf('Deleted subscribers (queue name=%s).', $params{'name'});
	$log->tracef('Exiting delete_subscribers: %d', 1);
	return 1;
}

=head2 add_alerts

Add alerts to a queue.

=over 8

=item Params: name, alerts.

=item Returns 1 if succcessful

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub add_alerts {
	my $self = shift;
	my %params = validate(
		@_, {
			'name' => { type => SCALAR, }, # queue name.
			'alerts' => { type => ARRAYREF,
				callbacks => {
					'Assert item content' => sub {
						use Data::Dumper;
						#print Dumper(\@{$_[0]});
						foreach my $alert (@{$_[0]}) {
							#print Dumper($alert);
							# TODO New function: Carp::Assert::More::assert_allowed(). Allowed keys in hash.
							assert_exists($alert, [ 'type', 'queue', 'trigger' ], 'Hash alert contains keys \'type\', \'queue\' and \'trigger\'.');
						}
						return 1;
					}
				}
			}, # An array of alert hashes containing required "type", "queue", "trigger", and optional "direction", "snooze" fields. Maximum number of alerts is 5.
		}
	);
	$log->tracef('Entering add_alerts(%s)', \%params);
	assert_nonblank( $params{'name'}, 'Parameter \'name\' is a non blank string');

	my $connection = $self->{'connection'};
	my %item_body;
	$item_body{'alerts'} = $params{'alerts'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronMQ::Api::IRONMQ_ADD_ALERTS_TO_A_QUEUE(),
			{
				'{Queue Name}' => $params{'name'},
				'body'         => \%item_body,
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;

	$log->tracef('Exiting add_alerts: %d', 1);
	return 1;
}

=head2 replace_alerts

Replace alerts to a queue. Replace the old alerts (if any) with these new ones.

=over 8

=item Params: name, alerts.

=item Returns 1 if succcessful

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub replace_alerts {
	my $self = shift;
	my %params = validate(
		@_, {
			'name' => { type => SCALAR, }, # queue name.
			'alerts' => { type => ARRAYREF,
				callbacks => {
					'Assert item content' => sub {
						use Data::Dumper;
						foreach my $alert (@{$_[0]}) {
							assert_exists($alert, [ 'type', 'queue', 'trigger' ], 'Hash alert contains keys \'type\', \'queue\' and \'trigger\'.');
						}
						return 1;
					}
				}
			}, # An array of alert hashes containing required "type", "queue", "trigger", and optional "direction", "snooze" fields. Maximum number of alerts is 5.
		}
	);
	$log->tracef('Entering replace_alerts(%s)', \%params);
	assert_nonblank( $params{'name'}, 'Parameter \'name\' is a non blank string');

	my $connection = $self->{'connection'};
	my %item_body;
	$item_body{'alerts'} = $params{'alerts'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronMQ::Api::IRONMQ_REPLACE_ALERTS_ON_A_QUEUE(),
			{
				'{Queue Name}' => $params{'name'},
				'body'         => \%item_body,
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;

	$log->tracef('Exiting replace_alerts: %d', 1);
	return 1;
}

=head2 delete_alerts

Delete the given alerts from the queue.

=over 8

=item Params: name, alerts.

=item 1

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub delete_alerts {
	my $self = shift;
	my %params = validate(
		@_, {
			'name' => { type => SCALAR, }, # queue name.
			'alerts' => { type => ARRAYREF, optional => 1,
				callbacks => {
					'Either parameter \'alerts\' or \'id\'' => sub {
						return exists$_[1]->{'id'} ? 0 : 1;
					},
					'Assert item content' => sub {
						#use Data::Dumper;
						foreach my $alert (@{$_[0]}) {
							#print Dumper($alert);
							assert_exists($alert, [ 'id' ], 'Hash alert contains key \'id\'.');
						}
						return 1;
					}
				},
			}, # An array of alerts hashes containing "id" field.
			'id' => { type => SCALAR, optional => 1,
				callbacks => {
					'Either parameter \'alerts\' or \'id\'' => sub {
						return exists$_[1]->{'alerts'} ? 0 : 1;
					},
				},
			}, # alert id.
			# TODO New function: Params::Validate::validate(), mutually exclusive parameters.
		}
	);
	$log->tracef('Entering delete_alerts(%s)', \%params);
	assert_nonblank( $params{'name'}, 'Parameter \'name\' is a non blank string');
	assert($params{'alerts'} || $params{'id'}, 'Have either parameter \'alerts\' or \'id\'.');

	my $connection = $self->{'connection'};
	if($params{'alerts'}) {
		my %item_body;
		$item_body{'alerts'} = $params{'alerts'};
		my ($http_status_code, $response_message) = $connection->perform_iron_action(
				IO::Iron::IronMQ::Api::IRONMQ_REMOVE_ALERTS_FROM_A_QUEUE(),
				{
					'{Queue Name}' => $params{'name'},
					'body'         => \%item_body,
				}
			);
		$self->{'last_http_status_code'} = $http_status_code;
	}
	else {
		my ($http_status_code, $response_message) = $connection->perform_iron_action(
				IO::Iron::IronMQ::Api::IRONMQ_REMOVE_ALERTS_FROM_A_QUEUE_BY_ID(),
				{
					'{Queue Name}' => $params{'name'},
					'{Alert ID}'   => $params{'id'},
				}
			);
		$self->{'last_http_status_code'} = $http_status_code;
	}

	$log->debugf('Deleted alerts (queue name=%s).', $params{'name'});
	$log->tracef('Exiting delete_alerts: %d', 1);
	return 1;
}

=head2 delete_queue

Delete an IronMQ queue.

=over 8

=item Params: queue name. Queue must exist. If not, fails with an exception.

=item Return: 1 == success.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub delete_queue {
	my $self = shift;
	my %params = validate(
		@_, {
			'name' => { type => SCALAR, }, # queue name.
		}
	);
	$log->tracef('Entering delete_queue(%s)', \%params);
	assert_nonblank( $params{'name'}, 'Parameter \'name\' is a non blank string');

	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronMQ::Api::IRONMQ_DELETE_A_MESSAGE_QUEUE(),
			{
				'{Queue Name}' => $params{'name'},
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;
	$log->debugf('Deleted queue (queue name=%s).', $params{'name'});
	$log->tracef('Exiting delete_queue: %d', 1);
	return 1;
}

=head2 get_queues

Return a IO::Iron::IronMQ::Queue objects representing message queues.

=over 8

=item Params: [None]

=item Return: List of IO::Iron::IronMQ::Queue objects.

=back

=cut

sub get_queues {
	my $self = shift;
	my %params = validate(
		@_, {
			# No parameters
		}
	);
	$log->tracef('Entering get_queues()');

	my @queues;
	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronMQ::Api::IRONMQ_LIST_MESSAGE_QUEUES(), { } );
	$self->{'last_http_status_code'} = $http_status_code;
	foreach my $queue_info (@{$response_message}) {
		my $get_queue_id = $queue_info->{'id'};
		my $get_queue_name = $queue_info->{'name'};
		my $queue = IO::Iron::IronMQ::Queue->new({
			'ironmq_client' => $self, # Pass a reference to the parent object.
			'id' => $get_queue_id,
			'name' => $get_queue_name,
			'connection' => $connection,
		});
		push @queues, $queue;
	}
	$log->debugf('Created %d IO::Iron::IronMQ::Queue objects.', scalar @queues);
	$log->debugf('Created queues: %s', \@queues);

	$log->tracef('Exiting get_queues: %s', \@queues);
	return @queues;
}

=head2 get_info_about_queue

=over 8

=item Params: queue name.

=item Return: a hash containing info about queue..

=back

=cut

sub get_info_about_queue {
	my $self = shift;
	my %params = validate(
		@_, {
			'name' => { type => SCALAR, }, # queue name.
		}
	);
	$log->tracef('Entering get_info_about_queue(%s)', \%params);
	assert_nonblank( $params{'name'}, 'Parameter \'name\' is a non blank string');

	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronMQ::Api::IRONMQ_GET_INFO_ABOUT_A_MESSAGE_QUEUE(),
			{ '{Queue Name}' => $params{'name'}, }
		);
	$self->{'last_http_status_code'} = $http_status_code;
	my $info = $response_message;
	# {"id":"51be[...]","name":"Log_Test_Queue","size":0,"total_messages":3,"project_id":"51bd[...]"}
	$log->debugf('Returned info about queue %s.', $params{'name'});
	$log->tracef('Exiting get_info_about_queue: %s', $info);
	return $info;
}


=head1 AUTHOR

Mikko Koivunalho, C<< <mikko.koivunalho at iki.fi> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-io-iron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-Iron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::Iron::IronMQ::Client


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

=item * Some get_*s (e.g. get messages) commands not yet implemented.

=item * The IronMQ client needs to control the queues, perhaps using semafores.

=item * A buffer mechanism to keep the messages while the IronMQ REST service is unavailable. IO::Iron::IronMQ::ASyncPush?

=item * Push queues.

=item * Mock IronMQ for testing.

=item * Rethink the using of REST:Client. Since message queues often involve a lot of traffic 
but always to the same address, REST:Client might not be the best solution.

=item * Handle message size issues: max 64KB; Includes the entire request (delay, timeout, expiration).

=item * Handle message delay, timeout and expiration min-max values.

Message Var	Default	Maximum	Notes
Message Size	--	64KB	Includes the entire request (delay, timeout, expiration).
Delay	0sec	604,800sec	Message is made available on queue after the delay expires.
Timeout	60sec	86,400sec	Message goes back on queue after timeout unless deleted.
Expiration	604,800sec	2,592,000sec	Equates to 7 days and 30 days, respectively.
Messages per Get	1	100	One or more messages can be handled at a time.

=item * Better logging, consistent log and error messages.

=item * Option to delete queue when IO::Iron::IronMQ::Queue object goes to garbage collection.



=item * Verify the client is connected when created by calling queues!

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

1; # End of IO::Iron::IronMQ::Client
