=begin comment
* Copyright (c) 2008-2015 Citrix Systems, Inc.
*
*   Licensed under the Apache License, Version 2.0 (the "License");
*   you may not use this file except in compliance with the License.
*   You may obtain a copy of the License at
*
*       http://www.apache.org/licenses/LICENSE-2.0
*
*  Unless required by applicable law or agreed to in writing, software
*   distributed under the License is distributed on an "AS IS" BASIS,
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*   See the License for the specific language governing permissions and
*   limitations under the License.
=end comment
=cut

package Nitro;

use strict;
use LWP;
use Carp;
use JSON;
use URI::Escape;
use Dumper;

# Login method : Used to login to netscaler and get session
# Arguments : ipaddress, username, password (of netscaler)
sub _login {

	my ($ipaddress,$username,$password,$ssl) = @_ ;

	if (!$ipaddress || $ipaddress eq "") {
		Carp::confess "Error : IP Address should not be null";
	}
	if (!$username || $username eq "") {
		Carp::confess "Error : Username should not be null";
	}
	if (!$password || $password eq "") {
		Carp::confess "Error : Password should not be null";
	}
	if ($ssl eq "") {
		Carp::confess "Error : SSL should not be null";
	}
	my $obj = undef;
        $obj->{username} = $username;
	$obj->{password} = $password;
#	if ($ssl) {
#		$protocol = 'https';
	#} else {
	#	$protocol = 'http';
	#}
	$protocol= 'https';
	my $payload = JSON->new->allow_blessed->convert_blessed->encode($obj);
	$payload = '{"login" :'.$payload."}";

	my $url = $protocol . "://$ipaddress/nitro/v1/config/login";
	my $contenttype = "application/vnd.com.citrix.netscaler.login+json";

	my $nitro_useragent = LWP::UserAgent->new;
	my $request = HTTP::Request->new( POST => $url );
	$request->header( 'Content-Type', $contenttype );
	$request->content($payload);

	my $response = $nitro_useragent->request($request);
	my $session = undef;
	if (HTTP::Status::is_error($response->code)) {
		$session = JSON->new->allow_blessed->convert_blessed->decode($response->content);
	} else {
		my $cookie = $response->header('Set-Cookie');
		if ($cookie && $cookie =~ /NITRO_AUTH_TOKEN=(.*);/) {
			$session->{sessionid} = uri_unescape($1);
		}
		$session->{errorcode} = 0;
		$session->{message} = "Done";
	}
	$session->{ns} = $ipaddress;
	$session->{protocol} = $protocol;
	$session->{username} = $username;
	$session->{password} = $password;
	return $session;
}

# POST method : Used to clear, enable, add, unset, bind, import, export and save the configuration
# Arguments : session, objecttype, object, operation
sub _post {

	my ($session, $objecttype, $object, $operation) = @_ ;

	if (!$session || $session eq "") {
		Carp::confess "Error : Session should not be null";
	}
	if (!($session->{sessionid})) {
		Carp::confess "Error : Not logged in";
	}
	if (!$objecttype || $objecttype eq "") {
		Carp::confess "Error : Object type should not be null";
	}
	if (!$object || $object eq "") {
		Carp::confess "Error : Object should not be null";
	}

    my $payload = JSON->new->allow_blessed->convert_blessed->encode($object);
    $payload = '{"'.$objecttype.'" :'.$payload."}";

	my $url = $session->{protocol} + "://$session->{ns}/nitro/v1/config/".$objecttype;
	if ($operation && $operation ne "add") {
		$url  = $url. "?action=".$operation;
	}
	my $contenttype = "application/vnd.com.citrix.netscaler.".$objecttype."+json";

	my $nitro_useragent = LWP::UserAgent->new;
	my $request = HTTP::Request->new(POST => $url);
	$request->header('Content-Type', $contenttype);
	$request->header('Set-Cookie', "NITRO_AUTH_TOKEN=".$session->{sessionid});
	$request->content($payload);

	my $response = $nitro_useragent->request($request);
	if (HTTP::Status::is_error($response->code)) {
		$response = JSON->new->allow_blessed->convert_blessed->decode($response->content);
	} else {
		$response->{errorcode} = 0;
		$response->{message} = "Done";
	}
	return $response;
}

# GET method : Used to get the details of configuration
# Arguments : session, objecttype, objectname, options
sub _get {

	my ($session, $objecttype, $objectname, $options) = @_ ;

	if (!$session || $session eq "") {
		Carp::confess "Error : Session should not be null";
	}
	if (!($session->{sessionid})) {
		Carp::confess "Error : Not logged in";
	}
	if (!$objecttype || $objecttype eq "") {
		Carp::confess "Error : Object type should not be null";
	}

	my $url = $session->{protocol} . "://$session->{ns}/nitro/v1/config/".$objecttype;
	if ($objectname && $objectname ne "") {
		$url  = $url."/".uri_escape(uri_escape($objectname));
	}
	if ($options && $options ne "") {
		$url = $url."?".$options;
	}
	my $contenttype = "application/vnd.com.citrix.netscaler.".$objecttype."+json";

	my $nitro_useragent = LWP::UserAgent->new;
	my $request = HTTP::Request->new(GET => $url);
	$request->header('Content-Type', $contenttype);
	$request->header('Set-Cookie', "NITRO_AUTH_TOKEN=".$session->{sessionid});

	my $response = $nitro_useragent->request($request);
	$response = JSON->new->allow_blessed->convert_blessed->decode($response->content);
	return $response;
}

# Get stats method : Used to get the stats of the configuration
# Arguments : session, objecttype, objectname
sub _get_stats {

	my ($session, $objecttype, $objectname) = @_ ;

	if (!$session || $session eq "") {
		Carp::confess "Error : Session should not be null";
	}
	if (!($session->{sessionid})) {
		Carp::confess "Error : Not logged in";
	}
	if (!$objecttype || $objecttype eq "") {
		Carp::confess "Error : Object type should not be null";
	}

	my $url = $session->{protocol} . "://$session->{ns}/nitro/v1/stat/".$objecttype;
	if ($objectname && $objectname ne "") {
		$url  = $url. "/".uri_escape(uri_escape($objectname));
	}
	my $contenttype = "application/vnd.com.citrix.netscaler.".$objecttype."+json";

	my $nitro_useragent = LWP::UserAgent->new;
	my $request = HTTP::Request->new(GET => $url);
	$request->header('Content-Type', $contenttype);
	$request->header('Set-Cookie', "NITRO_AUTH_TOKEN=".$session->{sessionid});

	my $response = $nitro_useragent->request($request);
	$response = JSON->new->allow_blessed->convert_blessed->decode($response->content);
	return $response;
}

# PUT method : Used to update the already existing configuration
# Arguments : session, objecttype, object, objectname
sub _put
{
	my ($session, $objecttype, $object, $objectname) = @_ ;

	if (!$session || $session eq "") {
		Carp::confess "Error : Session should not be null";
	}
	if (!($session->{sessionid})) {
		Carp::confess "Error : Not logged in";
	}
	if (!$objecttype || $objecttype eq "") {
		Carp::confess "Error : Object type should not be null";
	}
	if (!$object || $object eq "") {
		Carp::confess "Error : Object should not be null";
	}

	my $payload = JSON->new->allow_blessed->convert_blessed->encode($object);
        $payload = '{"'.$objecttype.'" :'.$payload."}";

	my $url = $session->{protocol} . "://$session->{ns}/nitro/v1/config/".$objecttype. "/".uri_escape(uri_escape($objectname));
	my $contenttype = "application/vnd.com.citrix.netscaler.".$objecttype."+json";

	my $nitro_useragent = LWP::UserAgent->new;
	my $request = HTTP::Request->new(PUT => $url);
	$request->header('Content-Type', $contenttype);
	$request->header('Set-Cookie', "NITRO_AUTH_TOKEN=".$session->{sessionid});
	$request->content($payload);

	my $response = $nitro_useragent->request($request);
	if (HTTP::Status::is_error($response->code)) {
		$response = JSON->new->allow_blessed->convert_blessed->decode($response->content);
	} else {
		$response->{errorcode} = 0;
		$response->{message} = "Done";
	}
	return $response;
}

# DELETE method : Used to delete, unbind the existing configuration
# Arguments : session, objecttype, object
sub _delete {

	my ($session, $objecttype, $object) = @_ ;

	if (!$session || $session eq "") {
		Carp::confess "Error : Session should not be null";
	}
	if (!($session->{sessionid})) {
		Carp::confess "Error : Not logged in";
	}
	if (!$objecttype || $objecttype eq "") {
		Carp::confess "Error : Object type should not be null";
	}
	if (!$object || $object eq "") {
		Carp::confess "Error : Object should not be null";
	}

        my $url = $session->{protocol} . "://$session->{ns}/nitro/v1/config/$objecttype";
	if (ref($object) eq 'HASH') {
		$url = $url."?args=";
		while ((my $key, my $value) = each %{$object}) {
			$url = $url.$key.":".uri_escape(uri_escape($value)).",";
		}
		$url =~ s/,$//;
	} else {
		$url  = $url."/".uri_escape(uri_escape($object));
	}
	my $contenttype = "application/vnd.com.citrix.netscaler.".$objecttype."+json";

	my $nitro_useragent = LWP::UserAgent->new;
	my $request = HTTP::Request->new(DELETE => $url);
	$request->header('Content-Type', $contenttype);
	$request->header('Set-Cookie', "NITRO_AUTH_TOKEN=".$session->{sessionid});

	my $response = $nitro_useragent->request($request);
	if (HTTP::Status::is_error($response->code)) {
		$response = JSON->new->allow_blessed->convert_blessed->decode($response->content);
	} else {
		$response->{errorcode} = 0;
		$response->{message} = "Done";
	}
	return $response;
}

# Logout method : Used to logout the netscaler
# Arguments : session
sub _logout {

	my ($session) = @_ ;

	if (!$session || $session eq "") {
		Carp::confess "Error : Session should not be null";
	}
	if (!($session->{sessionid})) {
		Carp::confess "Error : Not logged in";
	}

	my $payload = '{"logout" :{}}';

	my $url = $session->{protocol} . "://$session->{ns}/nitro/v1/config/logout";
	my $contenttype = "application/vnd.com.citrix.netscaler.logout+json";

	my $nitro_useragent = LWP::UserAgent->new;
	my $request = HTTP::Request->new(POST => $url);
	$request->header('Content-Type', $contenttype);
	$request->header('Set-Cookie', "NITRO_AUTH_TOKEN=".$session->{sessionid});
	$request->content($payload);

	my $response = $nitro_useragent->request($request);
	if (HTTP::Status::is_error($response->code)) {
		$response = JSON->new->allow_blessed->convert_blessed->decode($response->content);
	} else {
		$response->{errorcode} = 0;
		$response->{message} = "Done";
	}
	return $response;
}

1;

