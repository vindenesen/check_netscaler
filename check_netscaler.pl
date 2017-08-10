#!/usr/bin/perl
##############################################################################
# check_netscaler.pl
# Nagios Plugin for Citrix NetScaler
# Simon Lauger <simon@lauger.name>
#
# https://github.com/slauger/check_netscaler
#
# Version: 1.2 (2017-XX-XX)
#
# Copyright 2015-2017 Simon Lauger
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##############################################################################

use strict;
use warnings;

use LWP;
use JSON;
use URI::Escape;
use Data::Dumper;
use Nagios::Plugin;

my $plugin = Nagios::Plugin->new(
	plugin		=> 'check_netscaler',
	shortname	=> 'NetScaler',
	version		=> '1.1.1',
	url			=> 'https://github.com/slauger/check_netscaler',
	blurb		=> 'Nagios Plugin for Citrix NetScaler Appliance (VPX/MPX/SDX/CPX)',
	usage		=> 'Usage: %s -H <hostname> [ -u <username> ] [ -p <password> ]
-C <command> [ -o <objecttype> ] [ -n <objectname> ] [ -e <endpoint> ]
[ -w <warning> ] [ -c <critical> ] [ -v|--verbose ] [ -s|--ssl ] [ -t <timeout> ]',
	license		=> 'http://www.apache.org/licenses/LICENSE-2.0',
 	extra		=> '
This is a Nagios monitoring plugin for the Citrix NetScaler. The plugin works with
the Citrix NetScaler NITRO API. The goal of this plugin is to have a single plugin
for every important metric on the Citrix NetSaler.

This plugin works for NetScaler VPX, MPX, SDX and CPX appliances.

See https://github.com/slauger/check_netscaler for details.');

my @args = (
	{
		spec => 'hostname|H=s',
		usage => '-H, --hostname=STRING',
		desc => 'Hostname of the NetScaler appliance to connect to',
		required => 1,
	},
	{
		spec => 'username|u=s',
		usage => '-u, --username=STRING',
		desc => 'Username to log into box as (default: nsroot)',
		default  => 'nsroot',
		required => 0,
	},
	{
		spec => 'password|p=s',
		usage => '-p, --password=STRING',
		desc => 'Password for login username (default: nsroot)',
		default  => 'nsroot',
		required => 0,
	},
	{
		spec => 'ssl|s!',
		usage => '-s, --ssl',
		desc => 'Establish connection to NetScaler using SSL',
		default  => 0,
		required => 0,
	},
	{
		spec => 'port|P=i',
		usage => '-P, --port=INTEGER',
		desc => 'Establish connection to a alternate TCP Port',
		default => 0,
		required => 0,
	},
	{
		spec => 'command|C=s',
		usage => '-C, --command=STRING',
		desc => 'Check to be executed on the appliance',
		required => 1,
	},
	{
		spec => 'objecttype|o=s',
		usage => '-o, --objecttype=STRING',
		desc => 'Objecttype (target) to for the check command',
		required => 0,
	},
	{
		spec => 'objectname|n=s',
		usage => '-n, --objectname=STRING',
		desc => 'Filter request to a specific objectname',
		required => 0,
	},
	{
		spec => 'endpoint|e=s',
		usage => '-e, --endpoint=STRING',
		desc => 'Override option for the API endpoint (stat or config)',
		required => 0,
	},
	{
		spec => 'warning|w=s',
		usage => '-w, --warning=STRING',
		desc => 'Value for warning',
		required => 0,
	},
	{
		spec => 'critical|c=s',
		usage => '-c, --critical=STRING',
		desc => 'Value for critical',
		required => 0,
	},
);

foreach my $arg (@args) {
	add_arg($plugin, $arg);
}

$plugin->getopts;

if ($plugin->opts->command eq 'state') {
	# check for up/down state of vservers, service, servicegroup
	check_state($plugin);
} elsif ($plugin->opts->command eq 'above') {
	# check if a response is above a threshold
	check_threshold_above($plugin);
} elsif ($plugin->opts->command eq 'below') {
	# check if a response is below  a threshold
	check_threshold_below($plugin);
} elsif ($plugin->opts->command eq 'string') {
	# check if a response does contains a specific string
	check_string($plugin);
} elsif ($plugin->opts->command eq 'string_not') {
	# check if a response does not contains a specific string
	check_string_not($plugin);
} elsif ($plugin->opts->command eq 'sslcert') {
	# check for the lifetime of installed certificates
	check_sslcert($plugin);
} elsif ($plugin->opts->command eq 'nsconfig') {
	# check for unsaved configuration changes
	check_nsconfig($plugin);
} elsif ($plugin->opts->command eq 'staserver') {
	# check the state of the staservers
	check_staserver($plugin);
} elsif ($plugin->opts->command eq 'server') {
	# check the state of the servers
	check_server($plugin);
} elsif ($plugin->opts->command eq 'hwinfo') {
	# print infos about hardware and build version
	get_hardware_info($plugin);
} elsif ($plugin->opts->command eq 'interfaces') {
	# check the state of all interfaces
	check_interfaces($plugin);
} elsif ($plugin->opts->command eq 'debug') {
	# dump the full response of the nitro api
	check_debug($plugin);
} else {
	# error, unkown command given
	$plugin->nagios_die('unkown command ' . $plugin->opts->command . ' given');
}

sub add_arg
{
	my $plugin = shift;
	my $arg    = shift;

	my $spec     = $arg->{'spec'};
	my $help     = $arg->{'usage'};
	my $default  = $arg->{'default'};
	my $required = $arg->{'required'};

	if (defined $arg->{'desc'}) {
		my @desc;

		if (ref($arg->{'desc'})) {
			@desc = @{$arg->{'desc'}};
		}
		else {
			@desc = ( $arg->{'desc'} );
		}

		foreach my $d (@desc) {
			$help .= "\n   $d";
		}
	}

	$plugin->add_arg(
		spec     => $spec,
		help     => $help,
		default  => $default,
		required => $required,
	);
}

sub nitro_client {

	my $plugin  = shift;
	my $params  = shift;

	my $lwp = LWP::UserAgent->new(
		env_proxy => 1,
		keep_alive => 1,
		timeout => $plugin->opts->timeout,
		ssl_opts => {
			verify_hostname => 0,
			SSL_verify_mode => 0
		},
	);

	my $protocol = undef;

	if ($plugin->opts->ssl) {
		$protocol = 'https://';
	} else {
		$protocol = 'http://';
	}

	my $port = undef;

	if ($plugin->opts->port) {
		$port = ':' . $plugin->opts->port;
	} else {
		$port = '';
	}

	my $url = $protocol . $plugin->opts->hostname . $port . '/nitro/v1/' . $params->{'endpoint'} . '/' . $params->{'objecttype'};

	if ($params->{'objectname'} && $params->{'objectname'} ne '') {
		$url  = $url . '/' . uri_escape(uri_escape($params->{'objectname'}));
	}

	if ($params->{'options'} && $params->{'options'} ne '') {
		$url = $url . '?' . $params->{'options'};
	}

	if ($plugin->opts->verbose) {
		print "debug: target url is " . $url . "\n";
	}

	my $request = HTTP::Request->new(GET => $url);

	$request->header('X-NITRO-USER', $plugin->opts->username);
	$request->header('X-NITRO-PASS', $plugin->opts->password);
	$request->header('Content-Type', 'application/vnd.com.citrix.netscaler.' . $params->{'objecttype'} . '+json');

	my $response = $lwp->request($request);

	if ($plugin->opts->verbose) {
		print "debug: response of request is:\n";
		print Dumper($response->content);
	}

	if (HTTP::Status::is_error($response->code)) {
		$plugin->nagios_die($response->content);
	} else {
		$response = JSON->new->allow_blessed->convert_blessed->decode($response->content);
	}

	return $response;
}

sub check_state
{
	my $plugin = shift;

	if (!defined $plugin->opts->objecttype) {
		$plugin->nagios_die('command requires objecttype parameter');
	}

	my %counter;

	$counter{'up'}     = 0;
	$counter{'down'}   = 0;
	$counter{'oos'}    = 0;
	$counter{'unkown'} = 0;

	my %params;

	my $field_name;
	my $field_state;

	# well, i guess the citrix api developers were drunk
	if ($plugin->opts->objecttype eq 'service') {
		$params{'endpoint'} = $plugin->opts->endpoint || 'config';
		$field_name  = 'name';
		$field_state = 'svrstate';
	} elsif ($plugin->opts->objecttype eq 'servicegroup') {
		$params{'endpoint'} = $plugin->opts->endpoint || 'config';
		$field_name  = 'servicegroupname';
		$field_state = 'servicegroupeffectivestate';
	} else {
		$params{'endpoint'} = $plugin->opts->endpoint || 'stat';
		$field_name  = 'name';
		$field_state = 'state';
	}

	$params{'objecttype'} = $plugin->opts->objecttype;
	$params{'objectname'} = $plugin->opts->objectname;
	$params{'options'}    = undef;

	my $response = nitro_client($plugin, \%params);
	$response = $response->{$plugin->opts->objecttype};

	foreach my $response (@{$response}) {
		if ($response->{$field_state} eq 'UP') {
			$counter{'up'}++;
		}
		elsif ($response->{$field_state} eq 'DOWN') {
			$counter{'down'}++;
			$plugin->add_message(CRITICAL, $response->{$field_name} . ' down;');
		}
		elsif ($response->{$field_state} eq 'OUT OF SERVICE') {
			$counter{'oos'}++;
			$plugin->add_message(CRITICAL, $response->{$field_name} . ' oos;');
		}
		elsif ($response->{$field_state} eq 'UNKOWN') {
			$counter{'unkown'}++;
			$plugin->add_message(CRITICAL, $response->{$field_name} . ' unkown;');
		} else {
			$counter{'unkown'}++;
			$plugin->add_message(CRITICAL, $response->{$field_name} . ' unknown;');
		}
	}
	my ($code, $message) = $plugin->check_messages;

	my $stats = ' (' . $counter{'up'} . ' up, ' . $counter{'down'} . ' down, ' . $counter{'oos'} . ' oos, ' . $counter{'unkown'} . ' unkown)';

	$plugin->add_perfdata(
		label => 'up',
		value => $counter{'up'},
		min   => 0,
		max   => undef,
	);

	$plugin->add_perfdata(
		label => 'down',
		value => $counter{'down'},
		min   => 0,
		max   => undef,
	);

	$plugin->add_perfdata(
		label => 'oos',
		value => $counter{'oos'},
		min   => 0,
		max   => undef,
	);

	$plugin->add_perfdata(
		label => 'unkown',
		value => $counter{'unkown'},
		min   => 0,
		max   => undef,
	);

	if ($code == OK) {
		$plugin->nagios_exit($code, $plugin->opts->objecttype . ' OK' . $stats);
	} else {
		$plugin->nagios_exit($code, $plugin->opts->objecttype . ' ' . $message . $stats);
	}
}

sub check_string
{
	my $plugin = shift;

	if (!defined $plugin->opts->objecttype) {
		$plugin->nagios_die('command requires parameter for objecttype');
	}

	if (!defined $plugin->opts->objectname) {
		$plugin->nagios_die('command requires parameter for objectname');
	}

	if (!defined $plugin->opts->warning || !defined $plugin->opts->critical) {
		$plugin->nagios_die('command requires parameter for warning and critical');
	}

	my %params;
	$params{'endpoint'}   = $plugin->opts->endpoint || 'stat';
	$params{'objecttype'} = $plugin->opts->objecttype;
	$params{'objectname'} = undef;
	$params{'options'}    = undef;

	my $response = nitro_client($plugin, \%params);
	$response = $response->{$plugin->opts->objecttype};

	if ($response->{$plugin->opts->objectname} eq $plugin->opts->critical) {
		$plugin->nagios_exit(CRITICAL, $plugin->opts->objecttype . '::' . $plugin->opts->objectname . ' matches keyword (current: ' . $response->{$plugin->opts->objectname} . ', critical: ' . $plugin->opts->critical . ')');
	} elsif ($response->{$plugin->opts->objectname} eq $plugin->opts->warning) {
		$plugin->nagios_exit(WARNING, $plugin->opts->objecttype . '::' . $plugin->opts->objectname . ' matches keyword (current: ' . $response->{$plugin->opts->objectname} . ', warning: ' . $plugin->opts->warning . ')');
	} else {
		$plugin->nagios_exit(OK, $plugin->opts->objecttype . '::' . $plugin->opts->objectname . ' OK ('.$response->{$plugin->opts->objectname}.')');
	}
}

sub check_string_not
{
	my $plugin = shift;

	if (!defined $plugin->opts->objecttype) {
		$plugin->nagios_die('command requires parameter for objecttype');
	}

	if (!defined $plugin->opts->objectname) {
		$plugin->nagios_die('command requires parameter for objectname');
	}

	if (!defined $plugin->opts->warning || !defined $plugin->opts->critical) {
		$plugin->nagios_die('command requires parameter for warning and critical');
	}

	my %params;
	$params{'endpoint'}   = $plugin->opts->endpoint || 'stat';
	$params{'objecttype'} = $plugin->opts->objecttype;
	$params{'objectname'} = undef;
	$params{'options'}    = undef;

	my $response = nitro_client($plugin, \%params);
	$response = $response->{$plugin->opts->objecttype};

	if ($response->{$plugin->opts->objectname} ne $plugin->opts->critical) {
		$plugin->nagios_exit(CRITICAL, $plugin->opts->objecttype . '::' . $plugin->opts->objectname . ' not matches keyword (current: ' . $response->{$plugin->opts->objectname} . ', critical: ' . $plugin->opts->critical . ')');
	} elsif ($response->{$plugin->opts->objectname} ne $plugin->opts->warning) {
		$plugin->nagios_exit(WARNING, $plugin->opts->objecttype . '::' . $plugin->opts->objectname . ' not matches keyword (current: ' . $response->{$plugin->opts->objectname} . ', warning: ' . $plugin->opts->warning . ')');
	} else {
		$plugin->nagios_exit(OK, $plugin->opts->objecttype . '::' . $plugin->opts->objectname . ' OK ('.$response->{$plugin->opts->objectname}.')');
	}
}

sub check_threshold_above
{
	my $plugin = shift;

	if (!defined $plugin->opts->objecttype) {
		$plugin->nagios_die('command requires parameter for objecttype');
	}

	if (!defined $plugin->opts->objectname) {
		$plugin->nagios_die('command requires parameter for objectname');
	}

	if (!defined $plugin->opts->warning || !defined $plugin->opts->critical) {
		$plugin->nagios_die('command requires parameter for warning and critical');
	}

	my %params;
	$params{'endpoint'}   = $plugin->opts->endpoint || 'stat';
	$params{'objecttype'} = $plugin->opts->objecttype;
	$params{'objectname'} = undef;
	$params{'options'}    = undef;

	my $response = nitro_client($plugin, \%params);
	$response = $response->{$plugin->opts->objecttype};


	$plugin->add_perfdata(
		label    => $plugin->opts->objecttype . '::' . $plugin->opts->objectname,
		value    => $response->{$plugin->opts->objectname},
		min      => 0,
		max      => undef,
		warning  => $plugin->opts->warning,
		critical => $plugin->opts->critical,
	);

	if ($response->{$plugin->opts->objectname} >= $plugin->opts->critical) {
		$plugin->nagios_exit(CRITICAL, $plugin->opts->objecttype . '::' . $plugin->opts->objectname . ' is above threshold (current: ' . $response->{$plugin->opts->objectname} . ', critical: ' . $plugin->opts->critical . ')');
	} elsif ($response->{$plugin->opts->objectname} >= $plugin->opts->warning) {
		$plugin->nagios_exit(WARNING, $plugin->opts->objecttype . '::' . $plugin->opts->objectname . ' is above threshold (current: ' . $response->{$plugin->opts->objectname} . ', warning: ' . $plugin->opts->warning . ')');
	} else {
		$plugin->nagios_exit(OK, $plugin->opts->objecttype . '::' . $plugin->opts->objectname . ' OK ('.$response->{$plugin->opts->objectname}.')');
	}
}

sub check_threshold_below
{
	my $plugin = shift;

	if (!defined $plugin->opts->objecttype) {
		$plugin->nagios_die('command requires parameter for objecttype');
	}

	if (!defined $plugin->opts->objectname) {
		$plugin->nagios_die('command requires parameter for objectname');
	}

	if (!defined $plugin->opts->warning || !defined $plugin->opts->critical) {
		$plugin->nagios_die('command requires parameter for warning and critical');
	}

	my %params;
	$params{'endpoint'}   = $plugin->opts->endpoint || 'stat';
	$params{'objecttype'} = $plugin->opts->objecttype;
	$params{'objectname'} = undef;
	$params{'options'}    = undef;

	my $response = nitro_client($plugin, \%params);
	$response = $response->{$plugin->opts->objecttype};

	$plugin->add_perfdata(
		label    => $plugin->opts->objecttype . '::' . $plugin->opts->objectname,
		value    => $response->{$plugin->opts->objectname},
		min      => 0,
		max      => undef,
		warning  => $plugin->opts->warning,
		critical => $plugin->opts->critical,
	);

	if ($response->{$plugin->opts->objectname} <= $plugin->opts->critical) {
		$plugin->nagios_exit(CRITICAL, $plugin->opts->objecttype . '::' . $plugin->opts->objectname . ' is below threshold (current: ' . $response->{$plugin->opts->objectname} . ', critical: ' . $plugin->opts->critical . ')');
	} elsif ($response->{$plugin->opts->objectname} <= $plugin->opts->warning) {
		$plugin->nagios_exit(WARNING, $plugin->opts->objecttype . '::' . $plugin->opts->objectname . ' is below threshold (current: ' . $response->{$plugin->opts->objectname} . ', warning: ' . $plugin->opts->warning . ')');
	} else {
		$plugin->nagios_exit(OK, $plugin->opts->objecttype . '::' . $plugin->opts->objectname . ' ('.$response->{$plugin->opts->objectname}.')');
	}
}

sub check_sslcert
{
	my $plugin = shift;

	if (!defined $plugin->opts->warning || !defined $plugin->opts->critical) {
		$plugin->nagios_die('command requires parameter for warning and critical');
	}

	my %params;
	$params{'endpoint'}   = $plugin->opts->endpoint || 'config';
	$params{'objecttype'} = $plugin->opts->objecttype || 'sslcertkey';
	$params{'objectname'} = $plugin->opts->objectname;
	$params{'options'}    = undef;

	my $response = nitro_client($plugin, \%params);
	$response = $response->{$params{'objecttype'}};

	foreach $response (@{$response}) {
		if ($response->{daystoexpiration} <= $plugin->opts->critical) {
				$plugin->add_message(CRITICAL, $response->{certkey} . ' expires in ' . $response->{daystoexpiration} . ' days;');
		} elsif ($response->{daystoexpiration} <= $plugin->opts->warning) {
			$plugin->add_message(WARNING, $response->{certkey} . ' expires in ' . $response->{daystoexpiration} . ' days;');
		}
	}

	my ($code, $message) = $plugin->check_messages;

	if ($code == OK) {
		$plugin->nagios_exit($code, 'sslcertkey OK');
	} else {
		$plugin->nagios_exit($code, 'sslcertkey ' . $message);
	}
}

sub check_staserver
{
	my $plugin = shift;

	my %params;
	$params{'endpoint'}   = $plugin->opts->endpoint || 'config';
	$params{'objectname'} = $plugin->opts->objectname || '';
	$params{'options'}    = undef;

	if ($params{'objectname'} eq '') {
		$params{'objecttype'} = $plugin->opts->objecttype || 'vpnglobal_staserver_binding';
	} else {
		$params{'objecttype'} = $plugin->opts->objecttype || 'vpnvserver_staserver_binding';
	}

	my $response = nitro_client($plugin, \%params);
	$response = $response->{$params{'objecttype'}};

	# return critical if all staservers are down at once
	my $critical = 1;

	# check if any stas are in down state
	foreach $response (@{$response}) {
		if ($response->{'staauthid'} eq '') {
			$plugin->add_message(WARNING, $response->{'staserver'} . ' unavailable;');
		} else {
			$plugin->add_message(OK, $response->{'staserver'} . ' OK (' . $response->{'staauthid'}.');');
			$critical = 0;
		}
	}

	my ($code, $message) = $plugin->check_messages;

	if ( $critical == 1) { $code = CRITICAL ; }

	$plugin->nagios_exit($code, 'server ' . $message);
}

sub check_server
{
	my $plugin = shift;

	my %params;
	$params{'endpoint'}   = $plugin->opts->endpoint || 'config';
	$params{'objectname'} = $plugin->opts->objectname || '';
	$params{'options'}    = undef;
	$params{'objecttype'} = "server";

	my $response = nitro_client($plugin, \%params);
	$response = $response->{$params{'objecttype'}};

	# return critical if all staservers are down at once
	my $critical = 1;

	# check if any stas are in down state
	foreach $response (@{$response}) {
		if ($response->{'state'} ne 'ENABLED') {
			$plugin->add_message(WARNING, $response->{'name'} . ' ' . $response->{'state'} . ' ;');
		} else {
			$plugin->add_message(OK, $response->{'name'} . ' ' . $response->{'state'} . ' ;');
			$critical = 0;
		}
	}

	my ($code, $message) = $plugin->check_messages;

	if ( $critical == 1) { $code = CRITICAL ; }

	$plugin->nagios_exit($code, 'server ' . $message);
}

sub check_nsconfig
{
	my $plugin = shift;

	my %params;
	$params{'endpoint'}   = $plugin->opts->endpoint || 'config';
	$params{'objecttype'} = $plugin->opts->objecttype || 'nsconfig';
	$params{'objectname'} = undef;
	$params{'options'}    = undef;

	my $response = nitro_client($plugin, \%params);
	$response = $response->{$params{'objecttype'}};

	if (!defined $response->{'configchanged'} || $response->{'configchanged'}) {
		$plugin->nagios_exit(WARNING, 'nsconfig::configchanged unsaved configuration changes');
	} else {
		$plugin->nagios_exit(OK, 'nsconfig::configchanged OK');
	}
}

sub get_hardware_info
{
	my $plugin = shift;

	my %params;
	$params{'endpoint'}   = 'config';
	$params{'objecttype'} = 'nshardware';
	$params{'objectname'} = undef;
	$params{'options'}    = undef;

	my $response = nitro_client($plugin, \%params);
	$response = $response->{$params{'objecttype'}};

	$plugin->add_message(OK, "Platform: " . $response->{'hwdescription'} . ' ' . $response->{'sysid'} . ';');
	$plugin->add_message(OK, "Manufactured on: " . $response->{'manufactureyear'} . '/' . $response->{'manufacturemonth'} . '/' . $response->{'manufactureday'} . ';');
	$plugin->add_message(OK, "CPU: " . $response->{'cpufrequncy'} . 'MHz;');
	$plugin->add_message(OK, "Serial no: " . $response->{'serialno'} . ';');

	$params{'objecttype'} = 'nsversion';

	$response = nitro_client($plugin, \%params);
	$response = $response->{$params{'objecttype'}};

	$plugin->add_message(OK, "Build Version: " . $response->{'version'} . ';');

	my ($code, $message) = $plugin->check_messages;
	$plugin->nagios_exit($code, 'INFO: ' . $message);
}

sub check_interfaces
{
	my $plugin = shift;
	my @interface_errors;

	my %params;
	$params{'endpoint'}   = 'config';
	$params{'objecttype'} = 'interface';
	$params{'objectname'} = undef;
	$params{'options'}    = undef;

	my $response = nitro_client($plugin, \%params);

	foreach my $interface (@{$response->{'Interface'}}) {

		my $interface_state = OK;

		my $interface_speed = "N/A";
		if ($interface->{'actspeed'}) { $interface_speed = $interface->{'actspeed'}; }

		if ($interface->{'linkstate'} != 1 ) {
			push(@interface_errors, "interface " . $interface->{'devicename'} . " has linkstate \"DOWN\"");
			$interface_state = CRITICAL;
		}
		if ($interface->{'intfstate'} != 1 ) {
			push(@interface_errors, "interface " . $interface->{'devicename'} . " has intstate \"DOWN\"");
			$interface_state = CRITICAL;
		}
		if ($interface->{'state'} ne "ENABLED" ) {
			push(@interface_errors, "interface " . $interface->{'devicename'} . " has state \"".$interface->{'state'}."\"");
			$interface_state = CRITICAL;
		}

		$plugin->add_message($interface_state, "device: " . $interface->{'devicename'} . ' (speed: ' . $interface_speed . ', MTU: ' . $interface->{'actualmtu'} . ', VLAN: ' . $interface->{'vlan'} . ', type: ' . $interface->{'intftype'} . ') ' . $interface->{'state'} . ';');

		$plugin->add_perfdata(
			label    => "\'".$interface->{'devicename'} . "_rxbytes'",
			value    => $interface->{'rxbytes'}."B"
		);
		$plugin->add_perfdata(
			label    => "\'".$interface->{'devicename'} . "_txbytes'",
			value    => $interface->{'txbytes'}."B"
		);
		$plugin->add_perfdata(
			label    => "\'".$interface->{'devicename'} . "rxerrors'",
			value    => $interface->{'rxerrors'}."c"
		);
		$plugin->add_perfdata(
			label    => "\'".$interface->{'devicename'} . "txerrors'",
			value    => $interface->{'txerrors'}."c"
		);
	}

	my ($code, $message) = $plugin->check_messages;
	if (scalar @interface_errors != 0 ) {
		$message = join(", ",@interface_errors). " - ". $message
	}
	$plugin->nagios_exit($code, 'Interfaces: ' . $message);
}

sub check_debug
{
	my $plugin = shift;

	my %params;
	$params{'endpoint'}   = $plugin->opts->endpoint || 'stat';
	$params{'objecttype'} = $plugin->opts->objecttype;
	$params{'objectname'} = $plugin->opts->objectname;
	$params{'options'}    = undef;

	my $response = nitro_client($plugin, \%params);

	print Dumper($response);
}
