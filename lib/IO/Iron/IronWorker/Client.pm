package IO::Iron::IronWorker::Client;

## no critic (Documentation::RequirePodAtEnd
## no critic (Documentation::RequirePodSections)
## no critic (ControlStructures::ProhibitPostfixControls)
## no critic (Subroutines::RequireArgUnpacking)

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

IO::Iron::IronWorker::Client - IronWorker Client.

=cut

# VERSION: generated by DZP::OurPkgVersion


=head1 SYNOPSIS

	require IO::Iron::IronWorker::Client;

	my $ironworker_client = IO::Iron::IronWorker::Client->new();
	# or
	use IO::Iron qw(get_ironworker);
	my $iron_worker_client = get_ironworker();

	my $unique_code_package_name = 'HelloWorldCode';
	my $worker_as_zip; # Zipped Perl script and dependencies.
	my $unique_code_executable_file_name = 'HelloWorldCode.pl';
	my $uploaded = $iron_worker_client->update_code_package(
		'name' => $unique_code_package_name,
		'file' => $worker_as_zip,
		'file_name' => $unique_code_executable_file_name,
		'runtime' => 'perl',
	);

	my $code_package_id;
	my @code_packages = $iron_worker_client->list_code_packages();
	foreach (@code_packages) {
		if($_->{'name'} eq $unique_code_package_name) {
			$code_package_id = $_->{'id'};
			last;
		}
	}

	my $code_package = $iron_worker_client->get_info_about_code_package(
		'id' => $code_package_id
		);

	my @code_package_revisions = $iron_worker_client->
		list_code_package_revisions( 'id' => $code_package_id );

	my $downloaded = $iron_worker_client->download_code_package( 
		'id' => $code_package_id,
		'revision' => 1,
	);

	my $delete_rval = $iron_worker_client->delete( 'id' => $code_package_id );

	# Tasks
	my $task_payload = 'Task payload (can be JSONized)';
	my $task = $iron_worker_client->create_task(
		'code_name' => $unique_code_package_name,
		'payload'   => $task_payload,
		#
		# additional parameters for a task:
		# 'priority',        # The priority queue to run the task in. 
		                     # Valid values are 0, 1, and 2. 0 is the default.
		# 'timeout',         # The maximum runtime of your task in seconds.
		# 'delay',           # The number of seconds to delay before actually
		                     # queuing the task. Default is 0.
		# For scheduled task:
		# 'priority',        # The priority queue to run the task in.
		                     # Valid values are 0, 1, and 2. 0 is the default.
		# 'run_every',       # The amount of time, in seconds, between runs
		# 'end_at',          # The time tasks will stop being queued.
		                     # Should be a time or datetime.
		# 'run_times',       # The number of times a task will run.
		# 'start_at',        # The time the scheduled task should first be run.
		# 'name',            # Name of task or scheduled task.
	);

	# When queuing, the task object is updated with returned id.
	my $task_id = $iron_worker_client->queue( 'tasks' => $task );
	# Or:
	my @task_ids = $iron_worker_client->queue( 'tasks' => [ $task1, $task2 ] );
	# Or: 
	my $number_of_tasks_queued = $iron_worker_client->queue(
		'tasks' => [ $task1, $task2 ]
		);
	#
	my $task_id = $task->id();
	my $task_info = $iron_worker_client->get_info_about_task( 'id' => $task_id );
	until ($task_info->{'status'} =~ /(complete|error|killed|timeout)/) {
		sleep 3;
		$task_info = $iron_worker_client->get_info_about_task( 'id' => $task_id );
	}
	# $task->status() updates the task's information.
	my $task_duration = $task->duration();
	my $task_end_time = $task->end_time();
	my $task_updated_at = $task->updated_at();
	my $task_log = $task->log(); # Log is text/plain
	my $cancelled = $task->cancel();
	my $progress_set = $task->progress( { 
		'percent' => 25,
		'msg' => 'Not even halfway through!',
	} );
	my $retried = $task->retry();
	$task_id = $task->id(); # New task id after retry().

	my $task_info = $iron_worker_client->get_info_about_task( 'id' => $task_id );

	# Schedule task.
	my $schedule_task = $iron_worker_client->create_task(
		$unique_code_package_name,
		$task_payload,
		'priority' => 0,
		'run_every' => 120, # Every two minutes.
	);
	$schedule_task->run_times(5);
	my $end_dt = DateTime::...
	$schedule_task->end_at($end_dt);
	$schedule_task->start_at($end_dt);
	# When scheduling, the task object is updated with returned id.
	$schedule_task = $iron_worker_client->schedule( 'tasks' => $schedule_task);
	# Or:
	my @scheduled_tasks = $iron_worker_client->schedule(
		'tasks' => [$schedule_task1, $schedule_task2]
		);
	# Or: 
	my $number_of_scheduled_tasks = $iron_worker_client->schedule(
		'tasks' => [$schedule_task1, $schedule_task2]
		);
	#

	my $scheduled_task_info = $iron_worker_client->
		get_info_about_scheduled_task( 'id' => $task_id );
	

	my $from_time = time - (24*60*60);
	my $to_time = time - (1*60*60);
	my @tasks = $iron_worker_client->tasks(
		'code_name' => $unique_code_package_name, # Mandatory
		'status' => qw{queued running complete error cancelled killed timeout},
		'from_time' => $from_time, # Number of seconds since the Unix epoc
		'to_time' => $to_time, # Number of seconds since the Unix epoc
	);
	
	my @scheduled_tasks = $iron_worker_client->scheduled_tasks();

=head1 REQUIREMENTS

See L<IO::Iron|IO::Iron> for requirements.

=cut

use Log::Any  qw{$log};
use Hash::Util 0.06 qw{lock_keys lock_keys_plus unlock_keys legal_keys};
use Carp::Assert::More;
use English '-no_match_vars';
use Params::Validate qw(:all);

use IO::Iron::IronWorker::Api ();
use IO::Iron::Common ();
require IO::Iron::Connection;
require IO::Iron::IronWorker::Task;

# CONSTANTS for this package

# DEFAULTS


=head1 DESCRIPTION

IO::Iron::IronWorker is a client for the IronWorker remote worker system at L<http://www.iron.io/|http://www.iron.io/>.
IronWorker is a cloud based parallel multi-language worker platform. with a REST API.
IO::Iron::IronWorker creates a Perl object for interacting with IronWorker.
All IronWorker functions are available.

The class IO::Iron::IronWorker::Client instantiates the 'project', IronWorker access configuration.

=head2 IronWorker Cloud Parallel Workers

L<http://www.iron.io/|http://www.iron.io/>

IronWorker is a parallel worker platform delivered as a service to Internet connecting 
applications via its REST interface. Built with distributed 
cloud applications in mind, it provides on-demand scalability for workers, 
controls with HTTPS transport and cloud-optimized performance. [see L<http://www.iron.io/|http://www.iron.io/>]

=head2 Using the IronWorker Client Library

IO::Iron::IronWorker::Client is a normal Perl package meant to be used as an object.

    require IO::Iron::IronWorker::Client;
    my $ironworker_client = IO::Iron::IronWorker::Client->new();

Please see L<IO::Iron|IO::Iron> for further parameters and general usage.

=head2 Commands

After creating the client three sets of commands is available:

=over 8

=item Commands for operating code packages: 

=over 8

=item IO::Iron::IronWorker::Client::list_code_packages()

=item IO::Iron::IronWorker::Client::update_code_package(params)

=item IO::Iron::IronWorker::Client::get_info_about_code_package('id' => code_package_id)

=item IO::Iron::IronWorker::Client::delete_code_package('id' => code_package_id)

=item IO::Iron::IronWorker::Client::download_code_package('id' => code_package_id, params)

=item IO::Iron::IronWorker::Client::list_code_package_revisions('id' => code_package_id)

=back

=item Commands for operating tasks:

=over 8

=item IO::Iron::IronWorker::Client::create_task('code_name' => $name, 'payload' => $payload, ...)

=item IO::Iron::IronWorker::Client::tasks('code_name' => $code_name, ...)

=item IO::Iron::IronWorker::Client::queue(tasks => $task | [@tasks] )

=item IO::Iron::IronWorker::Client::get_info_about_task('id => $id)

=item IO::Iron::IronWorker::Task::log()

=item IO::Iron::IronWorker::Task::cancel()

=item IO::Iron::IronWorker::Task::set_progress('percent' => $number, 'msg' => $text)

=item retry_task()

=back

=item Commands for operating scheduled tasks:

=over 8

=item IO::Iron::IronWorker::Client::scheduled_tasks('code_name' => $code_name, ...)

=item IO::Iron::IronWorker::Client::schedule(tasks => $task | [@tasks] )

=item IO::Iron::IronWorker::Client::get_info_about_scheduled_task('id' => $id)

=item IO::Iron::IronWorker::Task::cancel_scheduled()

=back

=back

=head3 Operating code packages

A code package is simply a script program packed into Zip archive together 
with its dependency files (other libraries, configuration files, etc.).

After creating the zip file and reading it into a perl variable, upload it.
In the following example, the worker contains only one file
and we create the archive in the program - as opposed to creating it before
and simply reading it from a file before uploading it.

	require IO::Iron::IronWorker::Client;
	use IO::Compress::Zip;
	
	$iron_worker_client = IO::Iron::IronWorker::Client->new(
		'config' => 'iron_worker.json' 
	);

	my $worker_as_string_ = <<EOF;
	print qq{Hello, World!\n};
	EOF
	my $worker_as_zip;
	my $worker_
	
	IO::Compress::Zip::zip(\$worker_as_string => \$worker_as_zip);
	
	my $code_package_return_id = $iron_worker_client->update_code_package(
		'name' => 'HelloWorld_code_package', 
		'file' => $worker_as_string, 
		'file_name' => 'helloworld.pl', 
		'runtime' => 'perl', 
	);

With method list_code_packages() you can retrieve information about all 
the uploaded code packages. The method get_info_about_code_package()
will return information about only the requested code package.

	my @code_packages = $iron_worker_client->list_code_packages();
	foreach (@code_packages) {
		if($_->{'name'} eq 'HelloWorld_code_package) {
			$code_package_id = $_->{'id'};
			last;
		}
	}
	my $code_package = $iron_worker_client->get_info_about_code_package(
		'id' => $code_package_id,
		);

Method delete_code_package() removes the code package from IronWorker service.

	my $deleted = $iron_worker_client->delete_code_package(
		'id' => $code_package_id,
		);

The uploaded code package can be retrieved with method download_code_package().
The downloaded file is a zip archive.

	my $downloaded = $iron_worker_client->download_code_package( 
		'id' => $code_package_id, 'revision' => 1,
	);

The code packages get revision numbers according to their upload order.
The first upload of a code package gets revision number 1. Any subsequent 
upload of the same code package (same name) will get one higher 
revision number so the different uploads can be recognized.

	my @code_package_revisions = $iron_worker_client->list_code_package_revisions(
		'id' => $code_package_id,
	);

=head3 Operating tasks

Every task needs two parameters: the name of the code package on whose 
code they will run and a payload. The payload is passed to the code
package as a file. Payload is mandatory so if your code doesn't need it,
just insert an empty string. Payload can be any string, or stringified
object, normally JSON.

	my $task_payload = 'Task payload (could be JSONized object)';
	my $task = $iron_worker_client->create_task(
		'code_name' => $unique_code_package_name,
		'payload' => $task_payload,
		'priority' => 0,
	);
	my $task_code_package_name = $task->code_package_name();

Queue the task, i.e. put it to the queue for immediate execution.
"Immediate" doesn't mean that IronWorker will execute it right away,
just ASAP according to priority and delay parameters. When queuing,
the task object is updated with returned id.

	my $task_id = $iron_worker_client->queue('task' => $task);
	# Or:
	my @task_ids = $iron_worker_client->queue('task' => [$task1, $task2, ]);
	# Or: 
	my $number_of_tasks_queued = $iron_worker_client->queue(
		'task' => [$task1, $task2],
	);

Read the STDOUT log of the task.

	my $task_log = $task->log(); # Log is mime type text/plain

Cancel task if it's still in queue or currently being executed.

	my $cancelled = $task->cancel();

Change the "progress display" of the task.

	my $progress_set = $task->progress(
		'percent' => 25,
		'msg' => 'Not even halfway through!',
		);

Retry a failed task. You cannot change the payload. If the
payload is faulty, then you need to create a new task.

	my $new_task_id = $task->retry();
	# New task id after retry().

Get info about a task. Info is a hash structure.

	my $task_info = $iron_worker_client->get_info_about_task( 'task' => $task_id );

=head3 Operating scheduled tasks

Create a new task for scheduling.

	my $schedule_task = $iron_worker_client->create_task(
		'code_name' => $unique_code_package_name,
		'payload' => $task_payload,
		'priority' => 0,
		'run_every' => 120, # Every two minutes.
		);

Schedule the task or tasks. When scheduling, the task object is updated with returned id.

	$schedule_task = $iron_worker_client->schedule('task' => $schedule_task);
	# Or:
	my @scheduled_tasks = $iron_worker_client->schedule(
		'task' => [$schedule_task1, $schedule_task2]
	);
	# Or: 
	my $number_of_scheduled_tasks = $iron_worker_client->schedule(
		'task' => [$schedule_task1, $schedule_task2]
	);

Get information about the scheduled task.

	my $scheduled_task_info = $iron_worker_client->get_info_about_scheduled_task(
		'id' => $task_id
	);

Get all scheduled tasks as IO::Iron::IronWorker::Task objects.

	my @scheduled_tasks = $iron_worker_client->scheduled_tasks();


=head3 Exceptions

A REST call to IronWorker server may fail for several reason.
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
			legal_keys(%{$self}),
	);
	unlock_keys(%{$self});
	lock_keys_plus(%{$self}, @self_keys);
	my $config = IO::Iron::Common::get_config(%params);
	$log->debugf('The config: %s', $config);
	$self->{'project_id'} = defined $config->{'project_id'} ? $config->{'project_id'} : undef;
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
	$log->debugf('IronWorker Connection created with config: (project_id=%s; token=%s; host=%s; timeout=%s).', $config->{'project_id'}, $config->{'token'}, $config->{'host'}, $config->{'timeout'});
	$log->tracef('Exiting new: %s', $self);
	return $self;
}

###############################################
######## FUNCTIONS: CODE PACKAGES #############
###############################################

=head2 list_code_packages

Return a list of hashes containing information about every code package in IronWorker.

=over 8

=item Params: [None]

=item Return: List of hashes.

=back

See L</get_info_about_code_package> for an example of the returned hashes.

=cut

sub list_code_packages {
	my ($self) = @_;
	$log->tracef('Entering list_code_packages()');

	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronWorker::Api::IRONWORKER_LIST_CODE_PACKAGES(), { } );
	$self->{'last_http_status_code'} = $http_status_code;
	my @codes;
	foreach (@{$response_message}) {
		push @codes, $_;
	}
	$log->debugf('Returning %d code packages.', scalar @codes);
	$log->tracef('Exiting list_code_packages: %s', \@codes);
	return @codes;
}

=head2 update_code_package

Upload an IronWorker code package or update an existing code package.

=over 8

=item Params:

=over 8

=item name, code package name, mandatory.

=item file, the zip archive as a string buffer, optional if only updating other parameters.

=item file_name, the zip archive name, required if parameter 'file' is present.

=item runtime, the runtime type, e.g. sh, perl or ruby, required if parameter 'file' is present.

=item config, an (configuration) file for the code package, optional.

=item max_concurrency, number of concurrent runs, optional.

=item retries, number of retries, optional.

=item retries_delay, delay between retries, optional.

=back

=item Return: if successful, a new code package id.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub update_code_package {
	my $self = shift;
	my %params = validate(
		@_, {
			'name' => { type => SCALAR, }, # Code package name.
			'file' => { type => SCALAR, optional => 1, # The zip archive as a string buffer.
				depends => [ 'file_name', 'runtime' ], },
			'file_name' => { type => SCALAR, optional => 1 },  # Name of the zip file, not 
			'runtime' => { type => SCALAR, optional => 1, }, # The runtime type, e.g. sh, perl, ruby.
			'config' => { type => SCALAR, optional => 1, },
			'max_concurrency' => { type => SCALAR, optional => 1, },
			'retries' => { type => SCALAR, optional => 1, },
			'retries_delay' => { type => SCALAR, optional => 1, },
		}
	);
	$log->tracef('Entering update_code_package(%s)', \%params);
	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronWorker::Api::IRONWORKER_UPLOAD_OR_UPDATE_A_CODE_PACKAGE(),
			{
				'body'         => \%params,
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;
	my $id = $response_message->{'id'};
	$log->tracef('Exiting update_code_package: %s', $id);
	return $id;
}

=head2 get_info_about_code_package

=over 8

=item Params: code package id.

=item Return: a hash containing info about code package. Exception if code packages does not exist.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

Sample response (in JSON format):

	{
	    "id": "4eb1b241cddb13606500000b",
	    "project_id": "4eb1b240cddb13606500000a",
	    "name": "MyWorker",
	    "runtime": "ruby",
	    "latest_checksum": "a0702e9e9a84b758850d19ddd997cf4a",
	    "rev": 1,
	    "latest_history_id": "4eb1b241cddb13606500000c",
	    "latest_change": 1328737460598000000
	}

=cut

sub get_info_about_code_package {
	my $self = shift;
	my %params = validate(
		@_, {
			'id' => { type => SCALAR, }, # Code package id.
		}
	);
	$log->tracef('Entering get_info_about_code_package(%s)', \%params);
	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronWorker::Api::IRONWORKER_GET_INFO_ABOUT_A_CODE_PACKAGE(),
			{ '{Code ID}' => $params{'id'}, }
		);
	$self->{'last_http_status_code'} = $http_status_code;
	my $info = $response_message;
	$log->tracef('Exiting get_info_about_code_package: %s', $info);
	return $info;
}

=head2 delete_code_package

Delete an IronWorker code package.

=over 8

=item Params: code package id. Code package must exist. If not, fails with an exception.

=item Return: 1 == success.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub delete_code_package {
	my $self = shift;
	my %params = validate(
		@_, {
			'id' => { type => SCALAR, }, # Code package id.
		}
	);
	$log->tracef('Entering delete_code_package(%s)', $params{'id'});
	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronWorker::Api::IRONWORKER_DELETE_A_CODE_PACKAGE(),
			{
				'{Code ID}' => $params{'id'},
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;
	$log->tracef('Exiting delete_code_package: %d', 1);
	return 1;
}

=head2 download_code_package

Download an IronWorker code package.

=over 8

=item Params: code package id. Code package must exist. If not, fails with an exception.
subparam: revision.

=item Return: (list) the code package zipped (as it was uploaded), code package file name.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub download_code_package {
	my $self = shift;
	my %params = validate(
		@_, {
			'id' => { type => SCALAR, }, # Code package id.
			'revision' => { type => SCALAR, optional => 1, }, # Code package revision.
		}
	);
	$log->tracef('Entering download_code_package(%s)', \%params);
	my $connection = $self->{'connection'};
	my %query_params;
	$query_params{'{revision}'} = $params{'revision'} if $params{'revision'}; ## no critic (ControlStructures::ProhibitPostfixControls)
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronWorker::Api::IRONWORKER_DOWNLOAD_A_CODE_PACKAGE(),
			{
				'{Code ID}' => $params{'id'},
				%query_params,
			}
		);
	my $code_package = $response_message->{'file'};
	my $file_name = $response_message->{'file_name'};
	$self->{'last_http_status_code'} = $http_status_code;

	$log->tracef('Exiting download_code_package:%s, %s', $code_package, $file_name);
	return ($code_package, $file_name);
}

=head2 list_code_package_revisions

Return a list of hashes containing information about one code package revisions.

=over 8

=item Params: code package id. Code package must exist. If not, fails with an exception.

=item Return: List of hashes.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub list_code_package_revisions {
	my $self = shift;
	my %params = validate(
		@_, {
			'id' => { type => SCALAR, }, # Code package id.
		}
	);
	$log->tracef('Entering list_code_package_revisions(%s)', $params{'id'});

	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronWorker::Api::IRONWORKER_LIST_CODE_PACKAGE_REVISIONS(),
			{ '{Code ID}' => $params{'id'}, }
		);
	my @revisions;
	foreach (@{$response_message}) {
		push @revisions, $_;
	}
	$log->debugf('Returning %d code packages.', scalar @revisions);
	$log->tracef('Exiting list_code_package_revisions: %s', \@revisions);
	return @revisions;
}


###############################################
######## FUNCTIONS: TASK ######################
###############################################

=head2 create_task

=over 8

=item Params: code package name.

=item Return: an object of class IO::Iron::IronWorker::Task.

=back

This method does not access the IronWorker service.

=cut

sub create_task {
	my $self = shift;
	my %params = validate_with(
		'params' => \@_,
		'normalize_keys' => sub { return lc shift },
		'spec' => {
		'code_name' => { type => SCALAR, }, # Code package name.
		'payload' => { type => SCALAR, },  # Payload
		},
		'allow_extra' => 1,
    );
	$log->tracef('Entering create_task(%s)', \%params);

	my $connection = $self->{'connection'};

	my $task = IO::Iron::IronWorker::Task->new({
		'ironworker_client' => $self, # Pass a reference to the parent object.
		'connection' => $connection,
		%params,
	});

	$log->tracef('Exiting create_task: %s', $task);
	return $task;
}

=head2 tasks

Return a list of objects of class IO::Iron::IronWorker::Task,
every task in this IronWorker project.

=over 8

=item Params: code package name, params hash (status: queued|running|complete|error|cancelled|killed|timeout, from_time, to_time)

=item Return: List of objects.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub tasks {
	my $self = shift;
	my %params = validate(
		@_, {
			'code_name' => { type => SCALAR, }, # Code package name.
			'queued' => { type => SCALAR, 'optional' => 1, },
			'running' => { type => SCALAR, 'optional' => 1, },
			'complete' => { type => SCALAR, 'optional' => 1, },
			'error' => { type => SCALAR, 'optional' => 1, },
			'cancelled' => { type => SCALAR, 'optional' => 1, },
			'killed' => { type => SCALAR, 'optional' => 1, },
			'from_time' => { type => SCALAR, 'optional' => 1, },
			'to_time' => { type => SCALAR, 'optional' => 1, },
		}
	);
	$log->tracef('Entering tasks(%s, %s)', \%params);

	my $code_name = $params{'code_name'};
	delete $params{'code_name'};
	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronWorker::Api::IRONWORKER_LIST_TASKS(), {
				'{code_name}' => $code_name,
				%params,
			} );
	$self->{'last_http_status_code'} = $http_status_code;
	my @tasks;
	foreach (@{$response_message}) {
		$log->debugf('task info:%s', $_);
		push @tasks, $self->create_task(
			'code_name' => $_->{'code_name'},
			'payload' => $_->{'payload'} ? $_->{'payload'} : q{},
			%{$_},
		);
	}
	$log->debugf('Returning %d tasks.', scalar @tasks);
	$log->tracef('Exiting tasks: %s', \@tasks);
	return @tasks;
}

=head2 queue

Queue a new task or tasks for an IronWorker code package to execute.

=over 8

=item Params: one or more IO::Iron::IronWorker::Task objects.

=item Return: task id(s) returned from IronWorker (if in list context),
or number of tasks.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub queue {
	my $self = shift;
	my %validate_params = (
		'tasks' => { type => OBJECT | ARRAYREF, }, # ref to task.
		);
	my %params = validate(
		@_, {
			%validate_params
		}
	);
	lock_keys(%params, keys %validate_params);
	$log->tracef('Entering queue(%s)', \%params);

	my $connection = $self->{'connection'};
	my @message_tasks;
	if(ref $params{'tasks'} eq 'IO::Iron::IronWorker::Task') {
		$params{'tasks'} = [ $params{'tasks'} ];
	}
	foreach my $task (@{$params{'tasks'}}) {
		assert_isa( $task, 'IO::Iron::IronWorker::Task', 'task is IO::Iron::IronWorker::Task.');
		my %task_body;
		$task_body{'code_name'} = $task->{'code_name'};
		$task_body{'payload'} = $task->{'payload'};
		$task_body{'priority'} = $task->{'priority'} if defined $task->{'priority'};
		$task_body{'timeout'} = $task->{'timeout'} if defined $task->{'timeout'};
		$task_body{'delay'} = $task->{'delay'} if defined $task->{'delay'};
		$task_body{'name'} = $task->{'name'} if defined $task->{'name'};
		push @message_tasks, \%task_body;
	}

	my %message_body = ('tasks' => \@message_tasks);
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronWorker::Api::IRONWORKER_QUEUE_A_TASK(),
			{
				'body'         => \%message_body,
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;

	my @ids;
	my @ret_tasks = ( @{ $response_message->{'tasks'} } ); # tasks.
	foreach my $task (@{$params{'tasks'}}) {
		my $task_info = shift @ret_tasks; # We are using the same task objects.
		push @ids, $task_info->{'id'};
		$task->id( $task_info->{'id'} );
	}
	assert_is($response_message->{'msg'}, 'Queued up'); # Could be dangerous!
	$log->debugf( 'Queued IronWorker Task(s) (task id(s)=%s).', ( join q{,}, @ids ) );
	if (wantarray) {
		$log->tracef( 'Exiting queue: %s', ( join q{:}, @ids ) );
		return @ids;
	}
	else {
		if ( scalar @{$params{'tasks'}} == 1 ) {
			$log->tracef( 'Exiting queue: %s', $ids[0] );
			return $ids[0];
		}
		else {
			$log->tracef( 'Exiting queue: %s', scalar @ids );
			return scalar @ids;
		}
	}
}

=head2 get_info_about_task

=over 8

=item Params: task id.

=item Return: a hash containing info about a task. Exception if the task does not exist.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

Sample response (in JSON format):

	{
	    "id": "4eb1b471cddb136065000010",
	    "project_id": "4eb1b46fcddb13606500000d",
	    "code_id": "4eb1b46fcddb13606500000e",
	    "code_history_id": "4eb1b46fcddb13606500000f",
	    "status": "complete",
	    "code_name": "MyWorker",
	    "code_rev": "1",
	    "start_time": 1320268924000000000,
	    "end_time": 1320268924000000000,
	    "duration": 43,
	    "timeout": 3600,
	    "payload": "{\"foo\":\"bar\"}", 
	    "updated_at": "2012-11-10T18:31:08.064Z", 
	    "created_at": "2012-11-10T18:30:43.089Z"
	}

=cut

sub get_info_about_task {
	my $self = shift;
	my %params = validate(
		@_, {
			'id' => { type => SCALAR, }, # task id.
		}
	);
	$log->tracef('Entering get_info_about_task(%s)', \%params);

	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronWorker::Api::IRONWORKER_GET_INFO_ABOUT_A_TASK(),
			{ '{Task ID}' => $params{'id'}, }
		);
	$self->{'last_http_status_code'} = $http_status_code;
	my $info = $response_message;
	$log->tracef('Exiting get_info_about_task: %s', $info);
	return $info;
}

###############################################
######## FUNCTIONS: SCHEDULED TASK ############
###############################################

=head2 scheduled_tasks

Return a list of objects of class IO::Iron::IronWorker::Task,
every task in this IronWorker project.

=over 8

=item Params: code package name, params hash (status: queued|running|complete|error|cancelled|killed|timeout, from_time, to_time)

=item Return: List of objects.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub scheduled_tasks {
	my ($self) = @_;
	$log->tracef('Entering scheduled_tasks()');

	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronWorker::Api::IRONWORKER_LIST_SCHEDULED_TASKS(), { } );
	$self->{'last_http_status_code'} = $http_status_code;
	my @tasks;
	foreach (@{$response_message}) {
		$log->debugf('task info:%s', $_);
		push @tasks, $self->create_task(
			'code_name' => $_->{'code_name'},
			'payload' => $_->{'payload'} ? $_->{'payload'} : q{},
			%{$_},
		);
	}
	$log->debugf('Returning %d tasks.', scalar @tasks);
	$log->tracef('Exiting scheduled_tasks: %s', \@tasks);
	return @tasks;
}

=head2 schedule

Schedule a new task or tasks for an IronWorker code package to execute.

=over 8

=item Params: one or more IO::Iron::IronWorker::Task objects.

=item Return: scheduled task id(s) returned from IronWorker (if in list context),
or number of scheduled tasks.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

=cut

sub schedule {
	my $self = shift;
	my %validate_params = (
		'tasks' => { type => OBJECT | ARRAYREF, }, # ref to task.
		);
	my %params = validate(
		@_, {
			%validate_params
		}
	);
	lock_keys(%params, keys %validate_params);
	$log->tracef('Entering schedule(%s)', \%params);

	my $connection = $self->{'connection'};
	my @message_tasks;
	if(ref $params{'tasks'} eq 'IO::Iron::IronWorker::Task') {
		$log->debugf('The parameter is a single object.');
		$params{'tasks'} = [ $params{'tasks'} ];
	}
	foreach my $task (@{$params{'tasks'}}) {
		assert_isa( $task, 'IO::Iron::IronWorker::Task', 'task is IO::Iron::IronWorker::Task.');
		my %task_body;
		$task_body{'code_name'} = $task->{'code_name'};
		$task_body{'payload'} = $task->{'payload'};
		$task_body{'run_every'} = $task->{'run_every'} if defined $task->{'run_every'};
		$task_body{'end_at'} = $task->{'end_at'} if defined $task->{'end_at'};
		$task_body{'run_times'} = $task->{'run_times'} if defined $task->{'run_times'};
		$task_body{'priority'} = $task->{'priority'} if defined $task->{'priority'};
		$task_body{'start_at'} = $task->{'start_at'} if defined $task->{'start_at'};
		$task_body{'name'} = $task->{'name'} if defined $task->{'name'}; # Hm... documents do not mention but example does...
		push @message_tasks, \%task_body;
	}

	my %message_body = ('schedules' => \@message_tasks);
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronWorker::Api::IRONWORKER_SCHEDULE_A_TASK(),
			{
				'body'         => \%message_body,
			}
		);
	$self->{'last_http_status_code'} = $http_status_code;

	my ( @ids, $msg );
	my @ret_tasks = ( @{ $response_message->{'schedules'} } );    # scheduled tasks.
	foreach my $task (@{$params{'tasks'}}) {
		my $task_info = shift @ret_tasks;
		push @ids, $task_info->{'id'};
		$task->id( $task_info->{'id'} );
	}
	assert_is($response_message->{'msg'}, 'Scheduled'); # Could be dangerous!
	$msg = $response_message->{'msg'};    # Should be "Scheduled"
	$log->debugf( 'Scheduled IronWorker Task(s) (task id(s)=%s).', ( join q{,}, @ids ) );
	if (wantarray) {
		$log->tracef( 'Exiting schedule: %s', ( join q{:}, @ids ) );
		return @ids;
	}
	else {
		if ( scalar @{$params{'tasks'}} == 1 ) {
			$log->tracef( 'Exiting schedule: %s', $ids[0] );
			return $ids[0];
		}
		else {
			$log->tracef( 'Exiting schedule: %s', scalar @ids );
			return scalar @ids;
		}
	}
}

=head2 get_info_about_scheduled_task

=over 8

=item Params: task id.

=item Return: a hash containing info about a task. Exception if the task does not exist.

=item Exception: IronHTTPCallException if fails. (IronHTTPCallException: status_code=<HTTP status code> response_message=<response_message>)

=back

Sample response (in JSON format):

	{
	    "id": "4eb1b490cddb136065000011",
	    "created_at": "2011-11-02T21:22:51Z",
	    "updated_at": "2011-11-02T21:22:51Z",
	    "project_id": "4eb1b46fcddb13606500000d",
	    "msg": "Ran max times.",
	    "status": "complete",
	    "code_name": "MyWorker",
	    "delay": 10,
	    "start_at": "2011-11-02T21:22:34Z",
	    "end_at": "2262-04-11T23:47:16Z",
	    "next_start": "2011-11-02T21:22:34Z",
	    "last_run_time": "2011-11-02T21:22:51Z",
	    "run_times": 1,
	    "run_count": 1
	}

=cut

sub get_info_about_scheduled_task {
	my $self = shift;
	my %params = validate(
		@_, {
			'id' => { type => SCALAR, }, # task id.
		}
	);
	$log->tracef('Entering get_info_about_scheduled_task(%s)', \%params);

	my $connection = $self->{'connection'};
	my ($http_status_code, $response_message) = $connection->perform_iron_action(
			IO::Iron::IronWorker::Api::IRONWORKER_GET_INFO_ABOUT_A_SCHEDULED_TASK(),
			{ '{Schedule ID}' => $params{'id'}, }
		);
	$self->{'last_http_status_code'} = $http_status_code;
	my $info = $response_message;
	$log->tracef('Exiting get_info_about_scheduled_task: %s', $info);
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

    perldoc IO::Iron::IronWorker::Client


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

Cool idea, "workers in the cloud": http://www.iron.io/.


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

1; # End of IO::Iron::IronWorker::Client
