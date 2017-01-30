#!/usr/bin/perl
##############################################################################
# check_netscaler.pl
# Nagios Plugin for Citrix NetScaler 
# Simon Lauger <simon@lauger.name>
#
# https://github.com/slauger/check_netscaler
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
	shortname	=> 'check_netscaler',
	version		=> '0.2.0',
	url			=> 'https://github.com/slauger/check_netscaler',
	blurb		=> 'Nagios Plugin for Citrix NetScaler Appliance (VPX/MPX/SDX)',
	usage		=> "Usage: %s -H <hostname> [ -u <username> ] [ -p <password> ]
-C <command> [ -i <identifier> ] [ -f <filter> ] [ -e <endpoint> ]
[ -w <warning> ] [ -c <critical> ] [ -v|--verbose ] [ -s|--ssl ] [ -t <timeout> ]",
	license		=> 'http://www.apache.org/licenses/LICENSE-2.0',
 	extra     => '
This is a Nagios monitoring plugin for the Citrix NetScaler. The plugin works with
the Citrix NetScaler NITRO API. The goal of this plugin is to have a single plugin
for every important metric on the Citrix NetSaler.

This plugin works for NetScaler VPX, MPX and SDX appliances.

See https://github.com/slauger/check_netscaler for details.');

my @args = (
	{
		spec		=> 'hostname|H=s',
		usage		=> '-H, --hostname=STRING',
		desc		=> 'Hostname of the NetScaler appliance to connect to',
		required	=> 1,
	},
	{
		spec     => 'username|u=s',
		usage    => '-u, --username=STRING',
		desc     => 'Username to log into box as',
		default  => 'nsroot',
		required => 0,
	},
	{
		spec     => 'password|p=s',
		usage    => '-p, --password=STRING',
		desc     => 'Password for login username',
		default  => 'nsroot',
		required => 0,
	},
	{
		spec     => 'ssl|s!',
		usage    => '-s, --ssl',
		desc     => 'Establish connection to NetScaler using HTTPS',
		default  => 0,
		required => 0,
	},
	{
		spec	 => 'command|C=s',
		usage	 => '-C, --command=STRING',
		desc	 => 'Check to be executed on the appliance',
		required => 1,
	},
	{
		spec	 => 'identifier|i=s',
		usage	 => '-i, --identifier=STRING',
		desc	 => 'Identifier for command',
		required => 0,
	},
	{
		spec	 => 'endpoint|e=s',
		usage	 => '-e, --endpoint=STRING',
		desc	 => 'Override option for the API endpoint (stat or config)',
		required => 0,
	},
	{
		spec	 => 'filter|f=s',
		usage	 => '-f, --filter=STRING',
		desc	 => 'Filter for current command (might be a object name)',
		default  => '',
		required => 0,
	},
	{
		spec	=> 'warning|w=s',
		usage	=> '-w, --warning=STRING',
		desc	=> 'Value for warning',
		required => 0,
	},
	{
		spec	 => 'critical|c=s',
		usage	 => '-c, --critical=STRING',
		desc	 => 'Value for critical',
		required => 0,
	},	
);

foreach my $arg (@args) {
	add_arg($plugin, $arg);
}

$plugin->getopts;

# check for up/down state of vservers, service, servicegroup
if ($plugin->opts->command eq 'state') {
	check_state($plugin);
} elsif ($plugin->opts->command eq 'above') {
	check_threshold_above($plugin);
} elsif ($plugin->opts->command eq 'below') {
	check_threshold_below($plugin);
} elsif ($plugin->opts->command eq 'string') {
	check_string($plugin);
} elsif ($plugin->opts->command eq 'string_not') {
	check_string_not($plugin);
} elsif ($plugin->opts->command eq 'sslcerts') {
	check_sslcert($plugin);
} elsif ($plugin->opts->command eq 'dump') {
	check_debug($plugin);
} else {
	$plugin->nagios_die('unkown command ' . $plugin->opts->command . ' given', CRITICAL);
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
		
		if (defined $arg->{'default'}) {
			$help .= " (default: $arg->{'default'})";
		}
	}
	elsif (defined $arg->{'default'}) {
		$help .= "\n   (default: $arg->{'default'})";
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
	
	my $url = $protocol . $plugin->opts->hostname . '/nitro/v1/' . $params->{'endpoint'} . '/' . $params->{'objecttype'};
	
	if ($params->{'objectname'} && $params->{'objectname'} ne '') {
		$url  = $url . "/" . uri_escape(uri_escape($params->{'objectname'}));
	}
	
	if ($params->{'options'} && $params->{'options'} ne '') {
		$url = $url . "?" . $params->{'options'};
	}
	
	my $request = HTTP::Request->new(GET => $url);

	if ($plugin->opts->verbose) {
		print "debug: target url is " . $url . "\n";
	}
		
	$request->header('X-NITRO-USER', $plugin->opts->username);
	$request->header('X-NITRO-PASS', $plugin->opts->password);
	$request->header('Content-Type', 'application/vnd.com.citrix.netscaler.' . $params->{'objecttype'} . '+json');
	
	my $response = $lwp->request($request);
	
	#if ($plugin->opts->verbose) {
	#	print "debug: response of request was:";
	#	print Dumper($response->content);
	#}
	
	if (HTTP::Status::is_error($response->code)) {
		$plugin->nagios_die($response->content, CRITICAL);
	} else {
		$response = JSON->new->allow_blessed->convert_blessed->decode($response->content);
	}
	
	return $response;
}

sub check_state
{
	my $plugin = shift;
	
	if (!defined $plugin->opts->identifier) {
		$plugin->nagios_die('command requires identifier parameter', CRITICAL);
	}
	
	# @TODO: should be fixed (@FIXME)
	my %counter;
	my $counter;
	
	$counter{'up'}     = 0;
	$counter{'down'}   = 0;
	$counter{'oos'}    = 0;
	$counter{'unkown'} = 0;

	my %params;
	
	$params{'endpoint'}   = $plugin->opts->endpoint || 'stat';
	$params{'objecttype'} = $plugin->opts->identifier;
	$params{'objectname'} = $plugin->opts->filter;
	$params{'options'}    = undef;

	my $response = nitro_client($plugin, \%params);
	$response = $response->{$plugin->opts->identifier};
	
	foreach my $response (@{$response}) {
		# NetScaler API Bug: returns "ENABLED" instead of "UP" when requesting services/servicegroups
		if ($response->{'state'} eq 'UP' || $response->{'state'} eq 'ENABLED') {
			$counter->{'up'}++;
		}
		elsif ($response->{'state'} eq 'DOWN') {
			$counter->{'down'}++;
			$plugin->add_message(CRITICAL, $response->{'name'} . " down");
		}
		elsif ($response->{'state'} eq 'OUT OF SERVICE') {
			$counter->{'oos'}++;
			$plugin->add_message(CRITICAL, $response->{'name'} . " oos");
		}
		elsif ($response->{'state'} eq 'UNKOWN') {
			$counter->{'unkown'}++;
			$plugin->add_message(CRITICAL, $response->{'name'} . " unkown");
		} else {
			$counter->{'unkown'}++;
			$plugin->add_message(CRITICAL, $response->{'name'} . " unknown");
		}
	}		
	my ($code, $message) = $plugin->check_messages;
		
	my $stats = $counter->{'up'} . ' up, ' . $counter->{'down'} . ' down, ' . $counter->{'oos'} . ' oos, ' . $counter->{'unkown'} . ' unkown';
	
	$plugin->add_perfdata(
		label     => 'up',
		value     => $counter->{'up'},
		min       => 0,
		max       => undef,
		threshold => undef,
	);

	$plugin->add_perfdata(
		label     => 'down',
		value     => $counter->{'down'},
		min       => 0,
		max       => undef,
		threshold => undef,
	);

	$plugin->add_perfdata(
		label     => 'oos',
		value     => $counter->{'oos'},
		min       => 0,
		max       => undef,
		threshold => undef,
	);

	$plugin->add_perfdata(
		label     => 'unkown',
		value     => $counter->{'unkown'},
		min       => 0,
		max       => undef,
		threshold => undef,
	);
	
	$plugin->nagios_exit($code, 'NetScaler' . $plugin->opts->identifier . ' ' . $message . $stats);

}

sub check_string
{
	my $plugin = shift;
		
        if (!defined $plugin->opts->filter) {
                $plugin->nagios_die('command requires parameter for filter', CRITICAL);
        }

        if (!defined $plugin->opts->warning || !defined $plugin->opts->critical) {
                $plugin->nagios_die('command requires parameter for warning and critical', CRITICAL);
        }

		my %params;
		$params{'endpoint'}   = $plugin->opts->endpoint || 'stat';
		$params{'objecttype'} = $plugin->opts->identifier;
		$params{'objectname'} = undef;
		$params{'options'}    = undef;
	
		my $response = nitro_client($plugin, \%params);
		$response = $response->{$plugin->opts->identifier};


        if ($response->{$plugin->opts->filter} eq $plugin->opts->critical) {
                $plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " matches keyword [current: " . $response->{$plugin->opts->filter} . "; critical: " . $plugin->opts->critical . "]", CRITICAL);
        } elsif ($response->{$plugin->opts->filter} eq $plugin->opts->warning) {
                $plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " matches keyword [current: " . $response->{$plugin->opts->filter} . "; warning: " . $plugin->opts->warning . "]", WARNING);
        } else {
                $plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " [".$response->{$plugin->opts->filter}."]", OK);
        }
}

sub check_string_not
{
	my $plugin = shift;
		
        if (!defined $plugin->opts->filter) {
                $plugin->nagios_die('command requires parameter for filter', CRITICAL);
        }

        if (!defined $plugin->opts->warning || !defined $plugin->opts->critical) {
                $plugin->nagios_die('command requires parameter for warning and critical', CRITICAL);
        }

		my %params;
		$params{'endpoint'}   = $plugin->opts->endpoint || 'stat';
		$params{'objecttype'} = $plugin->opts->identifier;
		$params{'objectname'} = undef;
		$params{'options'}    = undef;
	
		my $response = nitro_client($plugin, \%params);
		$response = $response->{$plugin->opts->identifier};
	
		
        if ($response->{$plugin->opts->filter} ne $plugin->opts->critical) {
                $plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " not matches keyword [current: " . $response->{$plugin->opts->filter} . "; critical: " . $plugin->opts->critical . "]", CRITICAL);
        } elsif ($response->{$plugin->opts->filter} ne $plugin->opts->warning) { 
                $plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " not matches keyword [current: " . $response->{$plugin->opts->filter} . "; warning: " . $plugin->opts->warning . "]", WARNING);
        } else {
                $plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " [".$response->{$plugin->opts->filter}."]", OK);
        }
}

sub check_threshold_above
{
	my $plugin = shift;
		
	if (!defined $plugin->opts->filter) {
		$plugin->nagios_die('command requires parameter for filter', CRITICAL);
	}

	if (!defined $plugin->opts->warning || !defined $plugin->opts->critical) {
		$plugin->nagios_die('command requires parameter for warning and critical', CRITICAL);
	}

	my %params;
	$params{'endpoint'}   = $plugin->opts->endpoint || 'stat';
	$params{'objecttype'} = $plugin->opts->identifier;
	$params{'objectname'} = undef;
	$params{'options'}    = undef;
	
	my $response = nitro_client($plugin, \%params);
	$response = $response->{$plugin->opts->identifier};


        $plugin->add_perfdata(
                label     => $plugin->opts->identifier . "::" . $plugin->opts->filter,
                value     => $response->{$plugin->opts->filter},
                min       => 0,
                max       => undef,
                threshold => undef,
        );

	if ($response->{$plugin->opts->filter} >= $plugin->opts->critical) {
		$plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " is above threshold [current: " . $response->{$plugin->opts->filter} . "; critical: " . $plugin->opts->critical . "]", CRITICAL);
	} elsif ($response->{$plugin->opts->filter} >= $plugin->opts->warning) {
		$plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " is above threshold [current: " . $response->{$plugin->opts->filter} . "; warning: " . $plugin->opts->warning . "]", WARNING);
	} else {
		$plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " [".$response->{$plugin->opts->filter}."]", OK);
	}
}

sub check_threshold_below
{
	my $plugin = shift;
		
	if (!defined $plugin->opts->filter) {
		$plugin->nagios_die('command requires parameter for filter', CRITICAL);
	}

	if (!defined $plugin->opts->warning || !defined $plugin->opts->critical) {
		$plugin->nagios_die('command requires parameter for warning and critical', CRITICAL);
	}

	my %params;
	$params{'endpoint'}   = $plugin->opts->endpoint || 'stat';
	$params{'objecttype'} = $plugin->opts->identifier;
	$params{'objectname'} = undef;
	$params{'options'}    = undef;
	
	my $response = nitro_client($plugin, \%params);
	$response = $response->{$plugin->opts->identifier};

	$plugin->add_perfdata(
		label     => $plugin->opts->identifier . "::" . $plugin->opts->filter,
		value     => $response->{$plugin->opts->filter},
		min       => 0,
		max       => undef,
		threshold => undef,
	);

	if ($response->{$plugin->opts->filter} <= $plugin->opts->critical) {
		$plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " is below threshold [current: " . $response->{$plugin->opts->filter} . "; critical: " . $plugin->opts->critical . "]", CRITICAL);
	} elsif ($response->{$plugin->opts->filter} <= $plugin->opts->warning) {
		$plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " is below threshold [current: " . $response->{$plugin->opts->filter} . "; warning: " . $plugin->opts->warning . "]", WARNING);
	} else {
		$plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " [".$response->{$plugin->opts->filter}."]", OK);
	}
}

sub check_sslcert
{
	my $plugin = shift;
	
	my %params;
	$params{'endpoint'}   = $plugin->opts->endpoint || 'config';
	$params{'objecttype'} = $plugin->opts->identifier || 'sslcertkey';
	$params{'objectname'} = undef;
	$params{'options'}    = undef;
		
	if (!defined $plugin->opts->warning || !defined $plugin->opts->critical) {
		$plugin->nagios_die('command requires parameter for warning and critical', CRITICAL);
	}

    my $response = nitro_client($plugin, \%params);
	$response = $response->{$params{'objecttype'}};

	foreach $response (@{$response}) {
		if ($response->{daystoexpiration} <= $plugin->opts->critical) {
				$plugin->add_message(CRITICAL, $response->{certkey} . " expires in " . $response->{daystoexpiration} . " days;");
		} elsif ($response->{daystoexpiration} <= $plugin->opts->warning) {
			$plugin->add_message(WARNING, $response->{certkey} . " expires in " . $response->{daystoexpiration} . " days;");
		}
	}
	
	my ($code, $message) = $plugin->check_messages;
	
	$plugin->nagios_exit($code, "NetScaler SSLCerts " . $message);
}

sub check_debug
{
	my $plugin = shift;
	
	my %params;
	
	$params{'endpoint'}   = $plugin->opts->endpoint || 'stat';
	$params{'objecttype'} = $plugin->opts->identifier;
	$params{'objectname'} = $plugin->opts->filter;
	$params{'options'}    = undef;
	
	my $response = nitro_client($plugin, \%params);
	
	print Dumper($response);
}