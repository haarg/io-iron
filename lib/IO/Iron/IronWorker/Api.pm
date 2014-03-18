package IO::Iron::IronWorker::Api;

## no critic (Documentation::RequirePodAtEnd)
## no critic (Documentation::RequirePodSections)

use 5.008_001;
use strict;
use warnings FATAL => 'all';

# Global Creator
BEGIN {
	# No exports.
}

# Global Destructor
END {
}

=head1 NAME

IO::Iron::IronWorker::Api - IronWorker API reference for Perl Client Libraries!

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';


=head1 SYNOPSIS

This package is for internal use of IO::Iron::IronWorker::Client/Queue packages.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=cut

=head2 Code Packages

=head3 IRONWORKER_LIST_CODE_PACKAGES

/projects/{Project ID}/codes

=cut

sub IRONWORKER_LIST_CODE_PACKAGES {
	return {
			'action_name'    => 'IRONWORKER_LIST_CODE_PACKAGES',
			'href'           => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/codes',
			'action'         => 'GET',
			'return'         => 'LIST:codes',
			'retry'          => 0,
			'require_body'   => 0,
			'paged'          => 1,
			'per_page'       => 100,
			'url_escape'     => { '{Project ID}' => 1 },
			'log_message'    => '(project={Project ID}). Listed code packages.',
		};
}

=head3 IRONWORKER_UPLOAD_OR_UPDATE_A_CODE_PACKAGE

/projects/{Project ID}/codes

=cut

sub IRONWORKER_UPLOAD_OR_UPDATE_A_CODE_PACKAGE {
	return {
			'action_name'    => 'IRONWORKER_UPLOAD_OR_UPDATE_A_CODE_PACKAGE',
			'href'           => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/codes',
			'action'         => 'POST',
			'return'         => 'HASH',
			'retry'          => 1,
			'require_body'   => 1,
			'request_fields' => { 'name' => 1, 'file' => 1, 'file_name' => 1, 'runtime' => 1, 'config' => 1, 'max_concurrency' => 1, 'retries' => 1, 'retries_delay' => 1 },
			'url_escape'     => { '{Project ID}' => 1 },
			'content_type'   => 'multipart',
			'log_message'    => '(project={Project ID}). Uploaded or updated a code package.',
		};
}

=head3 IRONWORKER_GET_INFO_ABOUT_A_CODE_PACKAGE

/projects/{Project ID}/codes/{Code ID}

=cut

sub IRONWORKER_GET_INFO_ABOUT_A_CODE_PACKAGE {
	return {
			'action_name'    => 'IRONWORKER_GET_INFO_ABOUT_A_CODE_PACKAGE',
			'href'           => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/codes/{Code ID}',
			'action'         => 'GET',
			'return'         => 'HASH',
			'retry'          => 1,
			'require_body'   => 0,
			'url_escape'     => { '{Project ID}' => 1, '{Code ID}' => 1 },
			'log_message'    => '(project={Project ID}, code={Code ID}). Got info about a code package.',
		};
}

=head3 IRONWORKER_DELETE_A_CODE_PACKAGE

/projects/{Project ID}/codes/{Code ID}

=cut

sub IRONWORKER_DELETE_A_CODE_PACKAGE {
	return {
			'action_name'  => 'IRONWORKER_DELETE_A_CODE_PACKAGE',
			'href'         => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/codes/{Code ID}',
			'action'       => 'DELETE',
			'return'       => 'MESSAGE',
			'retry'        => 1,
			'require_body' => 0,
			'url_escape'   => { '{Project ID}' => 1, '{Code ID}' => 1 },
			'log_message'  => '(project={Project ID}, code={Code ID}). Deleted a code package.',
		};
}

=head3 IRONWORKER_DOWNLOAD_A_CODE_PACKAGE

/projects/{Project ID}/codes/{Code ID}/download

=cut

sub IRONWORKER_DOWNLOAD_A_CODE_PACKAGE {
	return {
			'action_name'    => 'IRONWORKER_DOWNLOAD_A_CODE_PACKAGE',
			'href'           => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/codes/{Code ID}/download',
			'action'         => 'GET',
			'return'         => 'BINARY',
			'retry'          => 1,
			'require_body'   => 0,
			'url_params'     => { 'revision' => 1 },
			'url_escape'     => { '{Project ID}' => 1, '{Code ID}' => 1 },
			'log_message'    => '(project={Project ID}, code={Code ID}). Downloaded a code package.',
		};
}

=head3 IRONWORKER_LIST_CODE_PACKAGE_REVISIONS

/projects/{Project ID}/codes/{Code ID}/revisions

=cut

sub IRONWORKER_LIST_CODE_PACKAGE_REVISIONS {
	return {
			'action_name'    => 'IRONWORKER_LIST_CODE_PACKAGE_REVISIONS',
			'href'           => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/codes/{Code ID}/revisions',
			'action'         => 'GET',
			'return'         => 'LIST:revisions',
			'retry'          => 1,
			'require_body'   => 0,
			'paged'          => 1,
			'per_page'       => 100,
			'url_escape'     => { '{Project ID}' => 1, '{Code ID}' => 1 },
			'log_message'    => '(project={Project ID}, code={Code ID}). Listed code package revisions.',
		};
}

=head2 Tasks

=head3 IRONWORKER_LIST_TASKS

/projects/{Project ID}/tasks

=cut

sub IRONWORKER_LIST_TASKS {
	return {
			'action_name'    => 'IRONWORKER_LIST_TASKS',
			'href'           => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/tasks',
			'action'         => 'GET',
			'return'         => 'LIST:tasks',
			'retry'          => 1,
			'require_body'   => 0,
			'paged'          => 1,
			'per_page'       => 100,
			'url_params'     => { 'code_name' => 1, 'queued' => 1, 'running' => 1, 'complete' => 1, 'error' => 1, 'cancelled' => 1, 'killed' => 1, 'timeout' => 1, 'from_time' => 1, 'to_time' => 1 },
			'url_escape'     => { '{Project ID}' => 1, 'code_name' => 1 },
			'log_message'    => '(project={Project ID}). Listed tasks.',
		};
}

=head3 IRONWORKER_QUEUE_A_TASK

/projects/{Project ID}/tasks

=cut

sub IRONWORKER_QUEUE_A_TASK {
	return {
			'action_name'    => 'IRONWORKER_QUEUE_A_TASK',
			'href'           => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/tasks',
			'action'         => 'POST',
			'return'         => 'HASH',
			'retry'          => 1,
			'require_body'   => 1,
			'request_fields' => { 'tasks' => 1 },
			'url_escape'     => { '{Project ID}' => 1 },
			'log_message'    => '(project={Project ID}). Queued tasks.',
		};
}

=head3 IRONWORKER_QUEUE_A_TASK_FROM_A_WEBHOOK

/projects/{Project ID}/tasks/webhook

=cut

sub IRONWORKER_QUEUE_A_TASK_FROM_A_WEBHOOK {
	return {
			'action_name'    => 'IRONWORKER_QUEUE_A_TASK_FROM_A_WEBHOOK',
			'href'           => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/tasks/webhook',
			'action'         => 'POST',
			'return'         => 'HASH',
			'retry'          => 1,
			'require_body'   => 1,
			'url_params'     => { 'code_name' => 1 },
			'url_escape'     => { '{Project ID}' => 1 },
			'log_message'    => '(project={Project ID}). Queued tasks.',
		}; # Request body will be passed along as the payload for the task.
}



=head3 IRONWORKER_GET_INFO_ABOUT_A_TASK

/projects/{Project ID}/tasks/{Task ID}

=cut

sub IRONWORKER_GET_INFO_ABOUT_A_TASK {
	return {
			'action_name'    => 'IRONWORKER_GET_INFO_ABOUT_A_TASK',
			'href'           => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/tasks/{Task ID}',
			'action'         => 'GET',
			'return'         => 'HASH',
			'retry'          => 1,
			'require_body'   => 0,
			'url_escape'     => { '{Project ID}' => 1, '{Task ID}' => 1 },
			'log_message'    => '(project={Project ID}, code={Task ID}). Got info about a task.',
		};
}

=head3 	IRONWORKER_GET_A_TASKS_LOG

/projects/{Project ID}/tasks/{Task ID}/log

=cut

sub IRONWORKER_GET_A_TASKS_LOG {
	return {
			'action_name'    => 'IRONWORKER_GET_A_TASKS_LOG',
			'href'           => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/tasks/{Task ID}/log',
			'action'         => 'GET',
			'return'         => 'PLAIN_TEXT',
			'retry'          => 1,
			'require_body'   => 0,
			'url_escape'     => { '{Project ID}' => 1, '{Task ID}' => 1 },
			'log_message'    => '(project={Project ID}, code={Task ID}). Got a task\'s log.',
		}; # Return plain text, not JSON!
}

=head3 IRONWORKER_CANCEL_A_TASK

/projects/{Project ID}/tasks/{Task ID}/cancel

=cut

sub IRONWORKER_CANCEL_A_TASK {
	return {
			'action_name'    => 'IRONWORKER_CANCEL_A_TASK',
			'href'           => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/tasks/{Task ID}/cancel',
			'action'         => 'POST',
			'return'         => 'MESSAGE',
			'retry'          => 1,
			'require_body'   => 0,
			'url_escape'     => { '{Project ID}' => 1, '{Task ID}' => 1,  },
			'log_message'    => '(project={Project ID}, task={Task ID}). Cancelled a task.',
		};
}

=head3 IRONWORKER_SET_A_TASKS_PROGRESS

/projects/{Project ID}/tasks/{Task ID}/progress

=cut

sub IRONWORKER_SET_A_TASKS_PROGRESS {
	return {
			'action_name'    => 'IRONWORKER_SET_A_TASKS_PROGRESS',
			'href'           => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/tasks/{Task ID}/progress',
			'action'         => 'POST',
			'return'         => 'MESSAGE',
			'retry'          => 1,
			'require_body'   => 1,
			'request_fields' => { 'percent' => 1, 'msg' => 1 },
			'url_escape'     => { '{Project ID}' => 1, '{Task ID}' => 1 },
			'log_message'    => '(project={Project ID}, code={Task ID}). Set task\'s progress.',
		};
}

=head3 IRONWORKER_RETRY_A_TASK

/projects/{Project ID}/tasks/{Task ID}/retry

=cut

sub IRONWORKER_RETRY_A_TASK {
	return {
			'action_name'    => 'IRONWORKER_RETRY_A_TASK',
			'href'           => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/tasks/{Task ID}/retry',
			'action'         => 'POST',
			'return'         => 'MESSAGE',
			'retry'          => 1,
			'require_body'   => 1,
			'request_fields' => { 'delay' => 1 },
			'url_escape'     => { '{Project ID}' => 1, '{Task ID}' => 1 },
			'log_message'    => '(project={Project ID}, code={Task ID}, delay={delay}). Task queued for retry.',
		};
}

=head2 Scheduled Tasks

=head3 IRONWORKER_LIST_SCHEDULED_TASKS

/projects/{Project ID}/schedules

=cut

sub IRONWORKER_LIST_SCHEDULED_TASKS {
	return {
			'action_name'    => 'IRONWORKER_LIST_SCHEDULED_TASKS',
			'href'           => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/schedules',
			'action'         => 'GET',
			'return'         => 'LIST:schedules',
			'retry'          => 1,
			'require_body'   => 0,
			'paged'          => 1,
			'per_page'       => 100,
			'url_escape'     => { '{Project ID}' => 1 },
			'log_message'    => '(project={Project ID}). Listed scheduled tasks.',
		};
}

=head3 IRONWORKER_SCHEDULE_A_TASK

/projects/{Project ID}/tasks

=cut

sub IRONWORKER_SCHEDULE_A_TASK {
	return {
			'action_name'    => 'IRONWORKER_SCHEDULE_A_TASK',
			'href'           => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/schedules',
			'action'         => 'POST',
			'return'         => 'HASH',
			'retry'          => 1,
			'require_body'   => 1,
			'request_fields' => { 'schedules' => 1 },
			'url_escape'     => { '{Project ID}' => 1 },
			'log_message'    => '(project={Project ID}). Scheduled task.',
		};
}

=head3 IRONWORKER_GET_INFO_ABOUT_A_SCHEDULED_TASK

/projects/{Project ID}/schedules/{Schedule ID}

=cut

sub IRONWORKER_GET_INFO_ABOUT_A_SCHEDULED_TASK {
	return {
			'action_name'    => 'IRONWORKER_GET_INFO_ABOUT_A_SCHEDULED_TASK',
			'href'           => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/schedules/{Schedule ID}',
			'action'         => 'GET',
			'return'         => 'HASH',
			'retry'          => 1,
			'require_body'   => 0,
			'url_escape'     => { '{Project ID}' => 1, '{Schedule ID}' => 1,  },
			'log_message'    => '(project={Project ID}, schedule={Schedule ID}). Got info about scheduled task.',
		};
}

=head3 IRONWORKER_CANCEL_A_SCHEDULED_TASK

/projects/{Project ID}/schedules/{Schedule ID}/cancel

=cut

sub IRONWORKER_CANCEL_A_SCHEDULED_TASK {
	return {
			'action_name'    => 'IRONWORKER_CANCEL_A_SCHEDULED_TASK',
			'href'           => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/schedules/{Schedule ID}/cancel',
			'action'         => 'POST',
			'return'         => 'MESSAGE',
			'retry'          => 1,
			'require_body'   => 0,
			'url_escape'     => { '{Project ID}' => 1, '{Schedule ID}' => 1,  },
			'log_message'    => '(project={Project ID}, schedule={Schedule ID}). Canceled scheduled task.',
		};
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

1; # End of IO::Iron::IronWorker::Api
