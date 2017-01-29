#!/usr/bin/perl -w
##############################################################################
# check_netscaler
# 
# Nagios Check Script Citrix NetScaler 
# Simon Lauger <simon@lauger.name>
#
# https://github.com/slauger/check_netscaler
#
# Copyright (c) 2015-2016 Simon Lauger <simon.lauger@teamix.de>
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###############################################################################

use strict;

use LWP;
use JSON;
use URI::Escape;
use Data::Dumper;
use Nagios::Plugin;

my $plugin = Nagios::Plugin->new(
	plugin		=> 'check_netscaler',
	shortname	=> 'check_netscaler',
	version		=> '0.2.0',
	url		=> 'https://github.com/slauger/check_netscaler',
	blurb		=> 'Nagios Plugin for Citrix NetScaler Appliance (VPX/MPX/SDX)',
	usage		=> "Usage: %s [ -v|--verbose ] [ -H <host> ] [ -U <username> ] [ -P <password> ] [ -t <timeout> ] -H <host> -C <command> [ -I <identifier> ] [ -F <filter> ]",
	license		=> "This nagios plugin is free software, and comes with ABSOLUTELY NO WARRANTY.
It may be used, redistributed and/or modified under the terms of the 3-Clause
BSD License (see http://opensource.org/licenses/BSD-3-Clause).",
 	extra     => "
This plugin connects to a Citrix NetScaler appliance trough the NITRO API and checks 
different parameters regarding vservers, servicegroups, services, loadbalancing, 
content switching, aaa and vpn. The goal of this project is to have one plugin for 
every important metric on the Citrix NetSaler.

This plugin also works for MPX/SDX NetScaler Appliances.

The Nitro.pm by Citrix (releases under the Apache License 2.0) is required for using this 
plugin. Use the Download tab in your NetScaler WebGUI for getting the Nitro.pm (part of the
Perl NITRO API samples)

This Plugin is written and maintained by Simon Lauger.

See https://github.com/slauger/check_netscaler for further information.");

my @args = (
	{
		spec     => 'hostname|H=s',
		usage    => '-H, --hostname=HOSTNAME',
		desc     => 'Hostname of the NetScaler appliance to connect to',
		required => 1,
	},
	{
		spec     => 'username|U=s',
		usage    => '-U, --username=USERNAME',
		desc     => 'Username to log into box as',
		default  => 'nsroot',
		required => 0,
	},
	{
		spec     => 'ssl|s=s',
		usage    => '-s, --ssl',
		desc     => 'Establish connection to NetScaler using HTTPS',
		default  => 'false',
		required => 0,
	},
	{
		spec     => 'password|P=s',
		usage    => '-P, --password=PASSWORD',
		desc     => 'Password for login username',
		default  => 'nsroot',
		required => 0,
	},
	{
		spec	 => 'command|C=s',
		usage	 => '-C, --command=COMMAND',
		desc	 => 'Check to be executed on the appliance',
		required => 1,
	},
	{
		spec	 => 'identifier|I=s',
		usage	 => '-I, --identifier=SUBCOMMAND',
		desc	 => 'Identifier for command',
		required => 0,
	},
	{
		spec	 => 'filter|F=s',
		usage	 => '-F, --filter=FILTER',
		desc	 => 'Filter for current command (might be a object name)',
		default  => '',
		required => 0,
	},
	{
		spec	=> 'warning|w=s',
		usage	=> '-w, --warning=INTEGER',
		desc	=> 'Value for warning',
		required => 0,
	},
	{
		spec	 => 'critical|c=s',
		usage	 => '-c, --critical=INTEGER',
		desc	 => 'Value for critical',
		required => 0,
	},	
);

foreach my $arg (@args) {
	add_arg($plugin, $arg);
}

$plugin->getopts;

if ($plugin->opts->command eq 'check_vserver') {
	check_vserver($plugin);
} elsif ($plugin->opts->command eq 'check_threshold_above') {
	check_threshold_above($plugin);
} elsif ($plugin->opts->command eq 'check_threshold_below') {
	check_threshold_below($plugin);
} elsif ($plugin->opts->command eq 'check_string') {
	check_string($plugin);
} elsif ($plugin->opts->command eq 'check_string_not') {
	check_string_not($plugin);
} elsif ($plugin->opts->command eq 'check_sslcert') {
	check_sslcert($plugin);
} elsif ($plugin->opts->command eq 'dump_stat') {
	dump_stat($plugin);
} elsif ($plugin->opts->command eq 'dump_config') {
	dump_config($plugin);
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
	
	print Dumper($params);
	
	my $lwp = LWP::UserAgent->new(
		env_proxy => 1, 
		keep_alive => 1, 
		timeout => 300, 
		ssl_opts => { 
			verify_hostname => 0, 
			SSL_verify_mode => 0
		},
	);
	
	my $protocol = undef;
	
	if ($plugin->opts->ssl eq 'true') {
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

sub check_vserver
{
	my $plugin = shift;
	
	if (!defined $plugin->opts->identifier) {
		$plugin->nagios_die('command requires identifier parameter', CRITICAL);
	}
	
	my %state = (
		'up'     => '',
		'down'   => '',
		'unkown' => '',
		'oos'    => '',
	);
	my %counter = (
		'up'     => 0,
		'down'   => 0,
		'unkown' => 0,
		'oos'    => 0,
	);

	my %params;
	
	$params{'endpoint'}   = 'stats';
	$params{'objecttype'} = $plugin->opts->identifier;
	$params{'objectname'} = $plugin->opts->filter;
	$params{'options'}    = undef;

	my $response = nitro_client($plugin, \%params);
	my $response = $response->{$plugin->opts->identifier};
	
	foreach my $response (@{$response}) {
		# NetScaler API Bug: returns "ENABLED" instead of "UP" when requesting services/servicegroups
		if ($response->{'state'} eq 'UP' || $response->{'state'} eq 'ENABLED') {
			$counter->{'up'}++;
		}
		elsif ($response->{'state'} eq 'DOWN') {
			$counter->{'down'}++;
			$plugin->add_message(CRITICAL, $response->{'name'} . " down");
		}
		elsif ($nitro_request->{'state'} eq "OUT OF SERVICE") {
			$counter->{'oos'}++;
			$plugin->add_message(CRITICAL, $response->{'name'} . " oos");
		}
		elsif ($nitro_request->{'state'} eq "UNKOWN") {
			$counter->{'unkown'}++;
			$plugin->add_message(CRITICAL, $response->{'name'} . " unkown");				
		} else {
			$counter->{'unkown'}++;
			$plugin->add_message(CRITICAL, $response->{'name'} . " unknown");				
		}
	}		
	my ($code, $message) = $plugin->check_messages;
		
	my $stats = $counter_up . ' up, ' . $counter_down . ' down, ' . $counter_oos . ' oos, ' . $counter_unkown . ' unkown';
	
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

	my $nitro_request = nitro_get_stats($session, $plugin->opts->identifier);

	if ($nitro_request->{errorcode} != 0) {
		$plugin->nagios_die($nitro_request->{message}, CRITICAL);
	}

	if ($plugin->opts->verbose) {
		print Dumper($nitro_request);
	}

	$nitro_request = $nitro_request->{$plugin->opts->identifier};

        if ($nitro_request->{$plugin->opts->filter} eq $plugin->opts->critical) {
                $plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " matches keyword [current: " . $nitro_request->{$plugin->opts->filter} . "; critical: " . $plugin->opts->critical . "]", CRITICAL);
        } elsif ($nitro_request->{$plugin->opts->filter} eq $plugin->opts->warning) {
                $plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " matches keyword [current: " . $nitro_request->{$plugin->opts->filter} . "; warning: " . $plugin->opts->warning . "]", WARNING);
        } else {
                $plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " [".$nitro_request->{$plugin->opts->filter}."]", OK);
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

        my $nitro_request = nitro_get_stats($session, $plugin->opts->identifier);

        if ($nitro_request->{errorcode} != 0) {
                $plugin->nagios_die($nitro_request->{message}, CRITICAL);
        }

        if ($plugin->opts->verbose) {
                print Dumper($nitro_request);
        }

        $nitro_request = $nitro_request->{$plugin->opts->identifier};

        if ($nitro_request->{$plugin->opts->filter} ne $plugin->opts->critical) {
                $plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " not matches keyword [current: " . $nitro_request->{$plugin->opts->filter} . "; critical: " . $plugin->opts->critical . "]", CRITICAL);
        } elsif ($nitro_request->{$plugin->opts->filter} ne $plugin->opts->warning) { 
                $plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " not matches keyword [current: " . $nitro_request->{$plugin->opts->filter} . "; warning: " . $plugin->opts->warning . "]", WARNING);
        } else {
                $plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " [".$nitro_request->{$plugin->opts->filter}."]", OK);
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

	my $nitro_request = nitro_get_stats($session, $plugin->opts->identifier);

	if ($nitro_request->{errorcode} != 0) {
		$plugin->nagios_die($nitro_request->{message}, CRITICAL);
	}

	$nitro_request = $nitro_request->{$plugin->opts->identifier};

	if ($plugin->opts->verbose) {
		print Dumper($nitro_request);
	}

        $plugin->add_perfdata(
                label     => $plugin->opts->identifier . "::" . $plugin->opts->filter,
                value     => $nitro_request->{$plugin->opts->filter},
                min       => 0,
                max       => undef,
                threshold => undef,
        );

	if ($nitro_request->{$plugin->opts->filter} >= $plugin->opts->critical) {
		$plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " is above threshold [current: " . $nitro_request->{$plugin->opts->filter} . "; critical: " . $plugin->opts->critical . "]", CRITICAL);
	} elsif ($nitro_request->{$plugin->opts->filter} >= $plugin->opts->warning) {
		$plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " is above threshold [current: " . $nitro_request->{$plugin->opts->filter} . "; warning: " . $plugin->opts->warning . "]", WARNING);
	} else {
		$plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " [".$nitro_request->{$plugin->opts->filter}."]", OK);
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

	my $nitro_request = nitro_get_stats($session, $plugin->opts->identifier);
	if ($nitro_request->{errorcode} != 0) {
		$plugin->nagios_die($nitro_request->{message}, CRITICAL);
	}

	$nitro_request = $nitro_request->{$plugin->opts->identifier};

	if ($plugin->opts->verbose) {
		print Dumper($nitro_request);
	}

        $plugin->add_perfdata(
                label     => $plugin->opts->identifier . "::" . $plugin->opts->filter,
                value     => $nitro_request->{$plugin->opts->filter},
                min       => 0,
                max       => undef,
                threshold => undef,
        );

	if ($nitro_request->{$plugin->opts->filter} <= $plugin->opts->critical) {
		$plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " is below threshold [current: " . $nitro_request->{$plugin->opts->filter} . "; critical: " . $plugin->opts->critical . "]", CRITICAL);
	} elsif ($nitro_request->{$plugin->opts->filter} <= $plugin->opts->warning) {
		$plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " is below threshold [current: " . $nitro_request->{$plugin->opts->filter} . "; warning: " . $plugin->opts->warning . "]", WARNING);
	} else {
		$plugin->nagios_die("NetScaler " . $plugin->opts->identifier . "::" . $plugin->opts->filter . " [".$nitro_request->{$plugin->opts->filter}."]", OK);
	}
}

sub check_sslcert
{
	my $plugin = shift;
	
	my %params;
	$params{'endpoint'}   = 'config';
	$params{'objecttype'} = $plugin->opts->identifier; # could also be hardcoded with 'sslcertkey'
	$params{'objectname'} = $plugin->opts->filter;
	$params{'options'}    = undef;
		
	if (!defined $plugin->opts->warning || !defined $plugin->opts->critical) {
		$plugin->nagios_die('command requires parameter for warning and critical', CRITICAL);
	}

    my $response = nitro_client($plugin, \%params);
	$response = $response->{$plugin->opts->identifier};

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

sub dump_stat
{
	my $plugin = shift;
	
	my %params;
	$params{'endpoint'}   = 'stat';
	$params{'objecttype'} = $plugin->opts->identifier;
	$params{'objectname'} = $plugin->opts->filter;
	$params{'options'}    = undef;
	
	my $response = nitro_client($plugin, \%params);
	
	print Dumper($response);
}

sub dump_config
{
	my $plugin = shift;
	
	my %params;
	
	$params{'endpoint'}   = 'config';
	$params{'objecttype'} = $plugin->opts->identifier;
	$params{'objectname'} = $plugin->opts->filter;
	$params{'options'}    = undef;
	
	my $response = nitro_client($plugin, \%params);
	
	print Dumper($response);
}