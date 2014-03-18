package IO::Iron::IronCache::Api;

## no critic (Documentation::RequirePodAtEnd)
## no critic (Documentation::RequirePodSections)

use 5.008_001;
use strict;
use warnings FATAL => 'all';

# Global Creator
BEGIN {
}

# Global Destructor
END {
}

=head1 NAME

IO::Iron::IronCache::Api - IronCache API reference for Perl Client Libraries!


=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';


=head1 SYNOPSIS

This package is for internal use of IO::Iron::IronCache::Client/Cache packages.


=head1 DESCRIPTION

The APIs to IronCache REST services.

=head1 FUNCTIONS

=cut


=head2 Operate caches.

=head3 IRONCACHE_LIST_CACHES

/projects/{Project ID}/caches

=cut

sub IRONCACHE_LIST_CACHES {
	return {
			'action_name'  => 'IRONCACHE_LIST_CACHES',
			'href'         => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/caches',
			'action'       => 'GET',
			'return'       => 'LIST',
			'retry'        => 0,
			'require_body' => 0,
			'paged'        => 1,
			'per_page'     => 100,
			'url_escape'   => { '{Project ID}' => 1 },
			'log_message'  => '(project={Project ID}). Listed caches.',
		};
}

=head3 IRONCACHE_GET_INFO_ABOUT_A_CACHE

/projects/{Project ID}/caches/{Cache Name}

=cut

sub IRONCACHE_GET_INFO_ABOUT_A_CACHE {
	return {
			'action_name'  => 'IRONCACHE_GET_INFO_ABOUT_A_CACHE',
			'href'         => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/caches/{Cache Name}',
			'action'       => 'GET',
			'return'       => 'HASH',
			'retry'        => 1,
			'require_body' => 0,
			'url_escape'   => { '{Project ID}' => 1, '{Cache Name}' => 1 },
			'log_message'  => '(project={Project ID}, cache={Cache Name}). Got info about a cache.',
		};
}

=head3 IRONCACHE_DELETE_A_CACHE

/projects/{Project ID}/caches/{Cache Name}

=cut

sub IRONCACHE_DELETE_A_CACHE {
	return {
			'action_name'  => 'IRONCACHE_DELETE_A_CACHE',
			'href'         => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/caches/{Cache Name}',
			'action'       => 'DELETE',
			'return'       => 'MESSAGE',
			'retry'        => 1,
			'require_body' => 0,
			'url_escape'   => { '{Project ID}' => 1, '{Cache Name}' => 1 },
			'log_message'  => '(project={Project ID}, cache={Cache Name}). Deleted cache.',
		};
}

=head2 Operate cache items.

=head3 IRONCACHE_CLEAR_A_CACHE

/projects/{Project ID}/caches/{Cache Name}/clear

=cut

sub IRONCACHE_CLEAR_A_CACHE {
	return {
			'action_name'  => 'IRONCACHE_CLEAR_A_CACHE',
			'href'         => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/caches/{Cache Name}/clear',
			'action'       => 'POST',
			'return'       => 'MESSAGE',
			'retry'        => 0,
			'require_body' => 0,
			'paged'        => 0,
			'per_page'     => 0,
			'url_escape'   => { '{Project ID}' => 1, '{Cache Name}' => 1 },
			'log_message'  => '(project={Project ID}, cache={Cache Name}). Cleared cache.',
		};
}

=head3 IRONCACHE_PUT_AN_ITEM_INTO_A_CACHE

/projects/{Project ID}/caches/{Cache Name}/items/{Key}

=cut

sub IRONCACHE_PUT_AN_ITEM_INTO_A_CACHE {
	return {
			'action_name'  => 'IRONCACHE_PUT_AN_ITEM_INTO_A_CACHE',
			'href'         => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/caches/{Cache Name}/items/{Key}',
			'action'       => 'PUT',
			'return'       => 'MESSAGE',
			'retry'        => 0,
			'require_body' => 1,
			'paged'        => 0,
			'per_page'     => 0,
			'request_fields' => {'value' => '{Value}', 'expires_in' => '{Expires In}', 'replace' => '{Replace}', 'add' => '{Put}', 'cas' => '{Cas}'},
			'url_escape'   => { '{Project ID}' => 1, '{Cache Name}' => 1, '{Key}' => 1 },
			'log_message'  => '(project={Project ID}, cache={Cache Name}, item={Key}). Put item into cache. Value: \'{Value}\', Expires in: \'{Expires In}\', Replace: \'{Replace}\', Put: \'{Put}\', Cas: \'{Cas}\'.',
		};
}

=head3 IRONCACHE_INCREMENT_AN_ITEMS_VALUE

/projects/{Project ID}/caches/{Cache Name}/items/{Key}/increment

=cut

sub IRONCACHE_INCREMENT_AN_ITEMS_VALUE {
	return {
			'action_name'  => 'IRONCACHE_INCREMENT_AN_ITEMS_VALUE',
			'href'         => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/caches/{Cache Name}/items/{Key}/increment',
			'action'       => 'POST',
			'return'       => 'HASH',
			'retry'        => 0,
			'require_body' => 1,
			'paged'        => 0,
			'per_page'     => 0,
			'request_fields' => {'amount' => '{Amount}'},
			'url_escape'   => { '{Project ID}' => 1, '{Cache Name}' => 1, '{Key}' => 1 },
			'log_message'  => '(project={Project ID}, cache={Cache Name}, item={Key}). Incremented items value by \'{Amount}\'.',
		};
}

=head3 IRONCACHE_GET_AN_ITEM_FROM_A_CACHE

/projects/{Project ID}/caches/{Cache Name}/items/{Key}

=cut

sub IRONCACHE_GET_AN_ITEM_FROM_A_CACHE {
	return {
			'action_name'  => 'IRONCACHE_GET_AN_ITEM_FROM_A_CACHE',
			'href'         => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/caches/{Cache Name}/items/{Key}',
			'action'       => 'GET',
			'return'       => 'HASH',
			'retry'        => 0,
			'require_body' => 0,
			'url_escape'   => { '{Project ID}' => 1, '{Cache Name}' => 1, '{Key}' => 1 },
			'log_message'  => '(project={Project ID}, cache={Cache Name}, item={Key}). Got item from cache.',
		};
}

=head3 IRONCACHE_DELETE_AN_ITEM_FROM_A_CACHE

/projects/{Project ID}/caches/{Cache Name}/items/{Key}

=cut

sub IRONCACHE_DELETE_AN_ITEM_FROM_A_CACHE {
	return {
			'action_name'  => 'IRONCACHE_DELETE_AN_ITEM_FROM_A_CACHE',
			'href'         => '{Protocol}://{Host}:{Port}{Host Path Prefix}/projects/{Project ID}/caches/{Cache Name}/items/{Key}',
			'action'       => 'DELETE',
			'return'       => 'MESSAGE',
			'retry'        => 0,
			'require_body' => 0,
			'url_escape'   => { '{Project ID}' => 1, '{Cache Name}' => 1, '{Key}' => 1 },
			'log_message'  => '(project={Project ID}, cache={Cache Name}, item={Key}). Deleted item from cache.',
		};
}


=head1 AUTHOR

Mikko Koivunalho, C<< <mikko.koivunalho at iki.fi> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-io-iron at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-IronMQ>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::Iron::IronCache::Client


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-IronMQ>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-IronMQ>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IO-IronMQ>

=item * Search CPAN

L<http://search.cpan.org/dist/IO-IronMQ/>

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

1; # End of IO::Iron::IronCache::Api
