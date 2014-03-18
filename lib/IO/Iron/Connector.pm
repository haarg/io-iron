package IO::Iron::Connector;

## no critic (Documentation::RequirePodAtEnd)
## no critic (Documentation::RequirePodSections)
## no critic (RegularExpressions::RequireExtendedFormatting)
## no critic (RegularExpressions::RequireLineBoundaryMatching)
## no critic (RegularExpressions::ProhibitEscapedMetacharacters)

use 5.008_001;
use strict;
use warnings FATAL => 'all';

# Global creator
BEGIN {
	use parent qw( IO::Iron::ConnectorBase ); # Inheritance
}

# Global destructor
END {
}

=head1 NAME

IO::Iron::Connector - REST API Connector, HTTP interface class.

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';


=head1 SYNOPSIS

This package is for internal use of IO::Iron packages.

=cut

use Log::Any  qw{$log};
use JSON ();
use Data::UUID ();
#use MIME::Base64 ();
use Hash::Util qw{lock_keys lock_keys_plus unlock_keys legal_keys};
use Carp::Assert;
use Carp::Assert::More;
use Carp;
use English '-no_match_vars';
use REST::Client ();
use URI::Escape qw{uri_escape_utf8};
use Try::Tiny;
use Scalar::Util qw{blessed looks_like_number};
use Exception::Class (
      'IronHTTPCallException' => {
      	fields => ['status_code', 'response_message'],
      }
  );

# CONSTANTS

use constant { ## no critic (ValuesAndExpressions::ProhibitConstantPragma)
	HTTP_CODE_OK_MIN => 200,
	HTTP_CODE_OK_MAX => 299,
	HTTP_CODE_SERVICE_UNAVAILABLE => 503,
};

=head1 DESCRIPTION

This class object handles the actual http traffic. Parameters are 
passed from the calling object (partly from API class) via Connection
class object. This class can be mocked and replaced when
the client objects are created.


=head1 SUBROUTINES/METHODS

=head2 new

Creator function.

=cut

sub new {
	my ($class) = @_;
	$log->tracef('Entering new(%s)', $class);
	my $self = IO::Iron::ConnectorBase->new();
	# Add more keys to the self hash.
	my @self_keys = (
			'client',        # REST client timeout (for REST calls accessing Iron services).
			'mime_boundary', # The boundary string separating parts in multipart REST messages.
			legal_keys(%{$self}),
	);
	unlock_keys(%{$self});
	bless $self, $class;
	lock_keys(%{$self}, @self_keys);

	# Set up REST client
	my $client = REST::Client->new();
	$self->{'client'} = $client;

	# Create MIME multipart message boundary string
	my $ug                   = Data::UUID->new();
	my $uuid1                = $ug->create();
	$self->{'mime_boundary'} = 'MIME_BOUNDARY_' . (substr $ug->to_string($uuid1), 1, 20); ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

	$log->infof('Iron Connector created with REST::Client as HTTP user agent.');
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

# TODO check why previous message (coded content) is in the next message!
sub perform_iron_action { ## no critic (Subroutines::ProhibitExcessComplexity)
	my ($self, $iron_action, $params) = @_;
	if(!defined $params) {
		$params = {};
	}
	$log->tracef('Entering Connector:perform_iron_action(%s, %s)', $iron_action, $params);

	my $href = $iron_action->{'href'};
	my $action_verb = $iron_action->{'action'};
	my $return_type = $iron_action->{'return'};
	my $retry = $iron_action->{'retry'};
	my $require_body = $iron_action->{'require_body'};
	my $paged = $iron_action->{'paged'} ? $iron_action->{'paged'} : 0;
	my $per_page = $iron_action->{'per_page'} ? $iron_action->{'per_page'} : 0;
	my $url_params = q{};
	if(exists $iron_action->{'url_params'} && ref $iron_action->{'url_params'} eq 'HASH') {
		foreach (keys %{$iron_action->{'url_params'}}) {
			$log->tracef('perform_iron_action(): url_param:%s', $_);
			if ($params->{'{'.$_.'}'}) {
				$url_params .= "$_={$_}&";
			}
		}
		$url_params = substr $url_params, 0, (length $url_params) - 1;
	}
	if ($url_params) {
		$href .= (q{?} . $url_params);
	}
	my $content_type = $iron_action->{'content_type'};
	$params->{'content_type'} = $content_type;
	$params->{'return_type'} = $return_type;
	$log->tracef('href before value substitution:\'%s\'.', $href);
	foreach my $value_key (sort keys %{$params}) {
		my $value = $params->{$value_key};
		$log->tracef('Param key:%s; value=%s;', $value_key, $value);
		$href =~ s/$value_key/$value/gs;
	};
	$log->tracef('href after value substitution:\'%s\'.', $href);

	my ($http_status_code, $returned_msg);
	my $keep_on_trying = 1;
	while($keep_on_trying) {
		$keep_on_trying = 0;
		try {
			assert(
					($require_body == 1 && defined $params->{'body'} && ref $params->{'body'} eq 'HASH')
					|| ($require_body == 0 && !defined $params->{'body'})
					);
			assert_in($action_verb, ['GET','PATCH','PUT','POST','DELETE','OPTIONS','HEAD'], 'action_verb is a valid HTTP verb.');
			assert_nonblank( $params->{'{Protocol}'}, 'params->{Protocol} is defined and not blank.' );
			assert_nonblank( $params->{'{Port}'}, 'params->{Port} is defined and not blank.' );
			assert_nonblank( $params->{'{Host}'}, 'params->{Host} is defined and not blank.' );
			assert_nonblank( $params->{'{Project ID}'}, 'params->{Project ID} is defined and not blank.' );
			assert_nonblank( $params->{'{Host Path Prefix}'}, 'params->{Host Path Prefix} is defined and not blank.' );
			assert_nonblank( $params->{'authorization_token'}, 'params->{authorization_token} is defined and not blank.' );
			assert_nonblank( $params->{'http_client_timeout'}, 'params->{http_client_timeout} is defined and not blank.' );
			my $url_escape_these_fields = defined $iron_action->{'url_escape'} ? $iron_action->{'url_escape'} : {};
			foreach my $field_name (keys %{$url_escape_these_fields}) {
				if (defined $params->{$field_name}) {
					$params->{$field_name} = uri_escape_utf8($params->{$field_name});
				}
			}
			#
			if($paged) {
				$log->debugf('A paged query.');
				my @returned_msgs;
				my ($http_status_code_temp, $returned_msg_temp);
				my $page_number = 0;
				while(1) {
					my $page_href = $href;
					$log->debugf('A paged query. Href:\'%s\'', $page_href);
					$page_href .= ($href =~ /\?/gsx ? q{&} : q{?}) . 'per_page='.$per_page.'&page='.$page_number;
					($http_status_code_temp, $returned_msg_temp) =
						$self->perform_http_action($action_verb, $page_href, $params);
					my $return_list = $returned_msg_temp;
					my ($return_type_def, $list_hash_key) = (split m/:/s, $return_type);
					$return_list = $returned_msg_temp->{$list_hash_key}
						if $return_type_def eq 'LIST' && defined $list_hash_key; ## no critic (ControlStructures::ProhibitPostfixControls)
					push @returned_msgs, @{$return_list};
					if( scalar @{$return_list} == 0 || @{$return_list} < $per_page ) {
						last;
					}
					$page_number++;
				}
				$http_status_code = $http_status_code_temp;
				$returned_msg = \@returned_msgs;
			}
			else {
				($http_status_code, $returned_msg) = $self->perform_http_action($action_verb, $href, $params);
			}
		}
		catch {
			$log->debugf('Caught exception');
			croak $_ unless blessed $_ && $_->can('rethrow'); ## no critic (ControlStructures::ProhibitPostfixControls)
			if ( $_->isa('IronHTTPCallException') ) {
				if( $_->status_code == HTTP_CODE_SERVICE_UNAVAILABLE() ) {
					# 503 Service Unavailable. Clients should implement exponential backoff to retry the request.
					$keep_on_trying = 1 if ($retry == 1); ## no critic (ControlStructures::ProhibitPostfixControls)
					# TODO Fix this temporary solution for backoff to retry the request.
				}
				else {
					$_->rethrow;
				}
			}
			else {
				$_->rethrow;
			}
		};
		# Module::Pluggable here?
	}
	$log->tracef('Exiting Connector:perform_iron_action(): %s', $returned_msg );
	return $http_status_code, $returned_msg;
}


=head2 perform_http_action

Do the actual "dirty work" of Internet connection.
This routine is only accessed internally.

=cut

sub perform_http_action {
	my ($self, $action_verb, $href, $params) = @_;
	my $client = $self->{'client'};
	# TODO assert href is URL
	assert_in($action_verb, ['GET','PATCH','PUT','POST','DELETE','OPTIONS','HEAD'], 'action_verb is a valid HTTP verb.');
	assert_exists($params, ['http_client_timeout', 'authorization_token'], 'params contains items body, http_client_timeout and authorization_token.');
	assert_integer($params->{'http_client_timeout'}, 'params->{\'http_client_timeout\'} is integer.');
	assert_nonblank($params->{'authorization_token'}, 'params->{\'authorization_token\'} is a non-blank string.');
	$log->tracef('Entering Connector:perform_http_action(%s, %s, %s)', $action_verb, $href, $params);
	#
	# HTTP request attributes
	my $timeout = $params->{'http_client_timeout'};
	my $request_body;
	# Headers
	my $content_type = $params->{'content_type'} ? $params->{'content_type'} : 'application/json';
	my $authorization = 'OAuth ' . $params->{'authorization_token'};
	#
	if($content_type =~ /multipart/is) {
		my $body_content = $params->{'body'} ? $params->{'body'} : { }; # Else use an empty hash for body.
		my $file_as_zip = $params->{'body'}->{'file'};
		delete $params->{'body'}->{'file'};
		my $encoded_body_content = JSON::encode_json($body_content);
		# Assert $params->{'file'}
		# Assert $params->{'file_name'}
		# Assert $params->{'file_name'} ends with ".zip"
		my $boundary = $self->{'mime_boundary'};
		$content_type = "multipart/form-data; boundary=$boundary";
		my $file_name = $params->{'body'}->{'file_name'} . '.zip';
		#$request_body = 'MIME-Version: 1.0' . "\n";
		#$request_body .= 'Content-Length: ' . $req_content_length . "\n";
		#$request_body .= 'Content-Type: ' . $req_content_type . "\n";
		$request_body = q{--} . $boundary . "\n";
		$request_body .= 'Content-Disposition: ' . 'form-data; name="data"' . "\n";
		$request_body .= 'Content-Type: ' . 'text/plain; charset=utf-8' . "\n";
		#$request_body .= 'Content-Type: ' . 'application/json; charset=utf-8' . "\n";
		$request_body .= "\n";
		$request_body .= $encoded_body_content . "\n";
		$request_body .= "\n";
		$request_body .= q{--} . $boundary . "\n";
		$request_body .= 'Content-Disposition: ' . 'form-data; name="file"; filename="' . $file_name . q{"} . "\n";
		$request_body .= 'Content-Type: ' . 'application/zip' . "\n";
		$request_body .= 'Content-Transfer-Encoding: base64' . "\n";
		$request_body .= "\n";
		#$request_body .= MIME::Base64::encode($file_as_zip) . "\n";
		$request_body .= $file_as_zip . "\n";
		$request_body .= q{--} . $boundary . q{--} . "\n";
	}
	else {
		my $body_content = $params->{'body'} ? $params->{'body'} : { }; # Else use an empty hash for body.
		$log->debugf('About to jsonize the body:\'%s\'', $body_content);
		foreach (keys %{$body_content}) {
			# Gimmick to ensure the proper jsonization of numbers
			# Otherwise numbers might end up as strings.
			$body_content->{$_} += 0 if looks_like_number $body_content->{$_}; ## no critic (ControlStructures::ProhibitPostfixControls)
		}
		my $encoded_body_content = JSON::encode_json($body_content);
		$log->debugf('Jsonized body:\'%s\'', $encoded_body_content);
		$request_body = $encoded_body_content;
	}
	$client->setTimeout($timeout);
	$log->tracef('client: %s; action=%s; href=%s;', $client, $action_verb, $href);
	$log->debugf('REST Request: [verb=%s; href=%s; body=%s; Headers: Content-Type=%s; Authorization=%s]', $action_verb, $href, $request_body, $content_type, $authorization);
	$client->request($action_verb, $href, $request_body,
			{
				'Content-Type' => $content_type,
				'Authorization' => $authorization,
			});
	# RETURN:
	$log->debugf('Returned HTTP response code:%s', $client->responseCode());
	$log->tracef('Returned HTTP response:%s', $client->responseContent());
	if( $client->responseCode() >= HTTP_CODE_OK_MIN() && $client->responseCode() <= HTTP_CODE_OK_MAX() ) {
		# 200 OK: Successful GET; 201 Created: Successful POST
		$log->tracef('HTTP Response code: %d, %s', $client->responseCode(), 'Successful!');
		my $decoded_body_content;
		if(defined $params->{'return_type'} && $params->{'return_type'} eq 'BINARY') {
			$log->tracef('Returned HTTP response header Content-Disposition:%s', $client->responseHeader('Content-Disposition'));
			my $filename;
			if($client->responseHeader ('Content-Disposition') =~ /filename=(.+)$/s) {
				$filename = $1 ? $1 : '[Unknown filename]';
			}
			$decoded_body_content = { 'file' => $client->responseContent(), 'file_name' => $filename };
		}
		elsif(defined $params->{'return_type'} && $params->{'return_type'} eq 'PLAIN_TEXT') {
			$decoded_body_content = $client->responseContent();
		}
		else {
			$decoded_body_content = JSON::decode_json( $client->responseContent() );
		}
		$log->tracef('Exiting Connector:perform_http_action(): %s, %s', $client->responseCode(), $decoded_body_content );
		return $client->responseCode(), $decoded_body_content;
	}
	else {
		$log->tracef('HTTP Response code: %d, %s', $client->responseCode(), 'Failure!');
		my $decoded_body_content;
		try {
			$decoded_body_content = JSON::decode_json( $client->responseContent() );
		};
		my $response_message = $decoded_body_content ? $decoded_body_content->{'msg'} : $client->responseContent();
		$log->tracef('Throwing exception in perform_http_action(): status_code=%s, response_message=%s', $client->responseCode(), $response_message );
		IronHTTPCallException->throw(
				status_code => $client->responseCode(),
				response_message => $response_message,
				error => 'IronHTTPCallException: status_code=' . $client->responseCode()
					. ' response_message=' . $response_message,
				);
	}
	return; # Control does not reach this point.
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

1; # End of IO::Iron::Connector
