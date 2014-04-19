#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Slurp;
use lib 't';
use lib 'integ_t';
require 'iron_io_integ_tests_common.pl';
plan tests => 6;
require IO::Iron::IronWorker::Client;

#use Log::Any::Adapter ('Stderr');    # Activate to get all log messages.
use Data::Dumper;
$Data::Dumper::Maxdepth = 4;
diag( "Testing IO::Iron::IronWorker::Client, Perl $], $^X" );
## Test case

my $worker_as_string_rev_01 = <<EOF;
#!/usr/bin/env perl
use 5.010; use strict; use warnings;
my %args = \@ARGV;
print qq{Hello, World!\\n};
print qq{ARGV values:\\n};
foreach my \$arg_key (keys %args) {
	print \$arg_key . q{ IS } . qq{\$args{\$arg_key}\\n};
}
EOF
#\$args{'arg1'} = 'arg1_content';

my $worker_as_zip_rev_01;
my $iron_worker_client;
my $unique_code_package_name_01;
my $unique_code_executable_name_01;
my $code_package_id;
subtest 'Setup for testing' => sub {
	plan tests => 1;

	# Create an IronWorker client.
	$iron_worker_client = IO::Iron::IronWorker::Client->new( 'config' => 'iron_worker.json' );

	# Create a new code package name.
	$unique_code_package_name_01    = create_unique_code_package_name();
	$unique_code_executable_name_01 = $unique_code_package_name_01 . '.sh';

	# Create archive
	my $zip = Archive::Zip->new();
	diag("Uploading this script: " . $worker_as_string_rev_01);

	# Pack wrapper into archive, rename into unique string
	my $perl_sh_wrapper_as_string;
	File::Slurp::read_file('integ_t/IronWorker/perl_sh_wrapper.sh', buf_ref => \$perl_sh_wrapper_as_string);
	{
		my $string_member = $zip->addString( $perl_sh_wrapper_as_string, $unique_code_executable_name_01 );
		$string_member->desiredCompressionMethod(COMPRESSION_DEFLATED);
	}

	# Pack worker into archive, rename into 'perl-pl.pl'
	my $string_member = $zip->addString( $worker_as_string_rev_01, 'iron-pl.pl');
	$string_member->desiredCompressionMethod(COMPRESSION_DEFLATED);
	use IO::String;
	my $io = IO::String->new($worker_as_zip_rev_01);
	{
		no warnings 'once';
		tie *IO, 'IO::String';
	}
	$zip->writeToFileHandle($io);
	isnt( $worker_as_zip_rev_01, $unique_code_executable_name_01, 'Compressed does not match with uncompressed.' );
	diag('Compressed two versions of the worker with zip.');
};

my @send_message_ids;
subtest 'Upload worker and confirm the upload' => sub {
	plan tests => 1;

	# Upload
	my $uploaded_code_id;
	$uploaded_code_id = $iron_worker_client->update_code_package(
		'name'      => $unique_code_package_name_01,
		'file'      => $worker_as_zip_rev_01,
		'file_name' => $unique_code_executable_name_01,
		##'runtime' => 'perl',
		##'runtime' => 'binary',
		'runtime' => 'sh',
	);
	isnt( $uploaded_code_id, undef, 'Code package uploaded.' );
	diag("Code package rev 1 uploaded.");
};

subtest 'confirm worker upload' => sub {
	plan tests => 3;

	# And confirm the upload...
	my @code_packages = $iron_worker_client->list_code_packages();
	foreach (@code_packages) {
		if ( $_->{'name'} eq $unique_code_package_name_01 ) {
			$code_package_id = $_->{'id'};
			last;
		}
	}
	isnt( $code_package_id, undef, 'Code package ID retrieved.' );
	diag("Code package rev 1 upload confirmed.");



	diag('Download and check...');
	my ($downloaded, $file_name) = $iron_worker_client->download_code_package( 
		'id' => $code_package_id,
		'revision' => 1,
		);
	my $zipped_contents = $downloaded;
	is($zipped_contents, $worker_as_zip_rev_01, 'Code package matches the original when zipped.');
	is($file_name, ($unique_code_package_name_01 . '_1.zip'), 'Code package file name matches the original with "_1.zip" suffix.');

	my $io = IO::String->new($zipped_contents);
	tie *IO, 'IO::String';
	my $zip = Archive::Zip->new();
	$zip->readFromFileHandle($io);
	my $downloaded_unzipped = $zip->contents($unique_code_executable_name_01);
	#is($downloaded_unzipped, $worker_as_string_rev_01, 'Code package matches the original unpacked.');

	diag("First release downloaded.");
	diag("First release($unique_code_executable_name_01):\n" . $downloaded_unzipped);
	$downloaded_unzipped = $zip->contents('iron-pl.pl');
	diag("First release($downloaded_unzipped):\n" . $downloaded_unzipped);
	
};

subtest 'Queue a task, confirm the creation, wait until finished, confirm log' => sub {
	plan tests => 3;

	# queue_task
	my $payload = 'Not used at this point!';
	my $task    = $iron_worker_client->create_task(
		'code_name' => $unique_code_package_name_01,
		'payload'   => $payload,
		'delay'     => 1,
		'name'      => $unique_code_package_name_01 . '_task',
	);
	my $ret_task_id = $iron_worker_client->queue( 'tasks' => $task );
	my $task_id = $task->id();
	is( $ret_task_id, $task_id, 'task object was updated with task id.' );
	my $task_info = $iron_worker_client->get_info_about_task( 'id' => $task_id );
	is( $task_info->{'id'}, $task_id, 'Task id matches with task id from get_info_about_task().' );
	diag("Wait for task completion.");

	until ( $task_info->{'status'} =~ /(complete|error|killed|timeout)/ ) {
		diag("Sleep 3 secs; query status again...");
		sleep 3;
		diag( "Status:" . $task_info->{'status'} );
		$task_info = $iron_worker_client->get_info_about_task( 'id' => $task_id );
	}
	diag("Task completed.");
	diag( "Status:" . $task_info->{'status'} );
	my $task_log = $task->log();
	diag( "Task log:" . $task_log );
	my $first_row_of_log = (split qq{\n}, $task_log)[0] . "\n" . (split qq{\n}, $task_log)[1];
	is( $first_row_of_log, "Hello, World!\nARGV values:", 'Task log matches.' );
};

subtest 'Queue a task, confirm the creation, cancel it, retry, set progress, wait until finished, confirm log' => sub {
	plan tests => 9;

	# queue_task
	#my $payload = JSON::encode_json({ 'first_name' => 'MyFirstName' });
	my $payload = 'Not used at this point!';
	my $task    = $iron_worker_client->create_task(
		'code_name' => $unique_code_package_name_01,
		'payload'   => $payload,
		##	'payload' => $payload,
		'delay' => 10,
		'name'  => $unique_code_package_name_01 . '_task_2',
	);
	my $ret_task_id = $iron_worker_client->queue( 'tasks' => $task );
	my $task_id = $task->id();
	is( $ret_task_id, $task_id, 'task object was updated with task id.' );
	my $task_info = $iron_worker_client->get_info_about_task( 'id' => $task_id );
	is( $task_info->{'id'},     $task_id );
	is( $task_info->{'status'}, 'queued', 'Task is queued.' );

	# cancel task
	$task->cancel();
	$task_info = $iron_worker_client->get_info_about_task( 'id' => $task_id );
	is( $task_info->{'status'}, 'cancelled', 'Task is cancelled.' );
	diag("Task is cancelled.");

	# retry task
	my $delay = 3;
	$delay += 0; # To double secure it is a number and JSON will treat it as a number!
	my $new_task_id = $task->retry( 'delay' => $delay );
	diag("Task is retried after 3 seconds.");
	diag("Wait for task completion.");
	$task_id = $task->id();    # New task id after retry().
	is( $new_task_id, $task_id, 'Task got a new id. Same as what retry() returned.' );
	diag("New task id from retry:$task_id.");

	# set progress
	$task_info = $iron_worker_client->get_info_about_task( 'id' => $task_id );
	until ( $task_info->{'status'} =~ /(complete|error|killed|timeout)/ ) {
		diag("Sleep 1 sec; query status again...");
		sleep 1;
		diag( "Status:" . $task_info->{'status'} );
		$task->set_progress( 'percent' => 10, 'msg' => 'One tenth done.' );
		$task_info = $iron_worker_client->get_info_about_task( 'id' => $task_id );
	}
	is( $task_info->{'msg'}, 'One tenth done.', 'Progress message matches.' );
	diag("Task completed.");
	diag( "Status:" . $task_info->{'status'} );
	$task->set_progress( 'percent' => 100, 'msg' => 'All done.' );
	$task_info = $iron_worker_client->get_info_about_task( 'id' => $task_id );
	is( $task_info->{'msg'}, 'All done.', 'Progress message matches.' );
	my $task_log = $task->log();
	diag( "Task log:" . $task_log );
	my $first_row_of_log = (split qq{\n}, $task_log)[0] . "\n" . (split qq{\n}, $task_log)[1];
	is( $first_row_of_log, "Hello, World!\nARGV values:", 'Task log matches.' );

	# list_tasks
	my $found;
	my $from_time = time - ( 24 * 60 * 60 );
	my $to_time   = time - ( 1 * 60 * 60 );
	my @tasks = $iron_worker_client->tasks(
		'code_name' => $unique_code_package_name_01,
		'complete'  => 1,

		#'from_time' => $from_time,
		#'to_time' => $to_time,
	);
	diag( 'Found ' . scalar @tasks . ' tasks.' );
	foreach (@tasks) {
		if ( $_->id() eq $task_id ) {
			$found = $_->id();
			last;
		}
	}
	isnt( $found, undef, 'Code package ID retrieved.' );
};

subtest 'Clean up.' => sub {
	plan tests => 2;
	my $deleted = $iron_worker_client->delete_code_package( 'id' => $code_package_id );
	is( $deleted, 1, 'Code package deleted.' );
	my @code_packages = $iron_worker_client->list_code_packages();
	my $found;
	foreach (@code_packages) {
		if ( $_->{'name'} eq $unique_code_package_name_01 ) {
			$found = $_->{'id'};
			last;
		}
	}
	is( $found, undef, 'Code package not exists. Delete confirmed.' );
	diag("Code package deleted.");
};
