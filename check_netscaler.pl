#!/usr/bin/perl -w
################################################################################
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
################################################################################

use Nitro;
use Nagios::Plugin;
use Data::Dumper;

use strict;

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

if (!defined $plugin->opts->hostname) {
	$plugin->nagios_die('missing hostname argument', CRITICAL);
}

my $session = Nitro::_login($plugin->opts->hostname, $plugin->opts->username, $plugin->opts->password, $plugin->opts->ssl);

if ($session->{errorcode} != 0 || !($session->{sessionid})) {
	$plugin->die("ERROR: " . $session->{message});
}

if ($plugin->opts->command eq 'check_vserver') {
	check_vserver();
} elsif ($plugin->opts->command eq 'check_threshold_above') {
	check_threshold_above();
} elsif ($plugin->opts->command eq 'check_threshold_below') {
	check_threshold_below();
} elsif ($plugin->opts->command eq 'check_string') {
	check_string();
} elsif ($plugin->opts->command eq 'check_string_not') {
	check_string_not();
} elsif ($plugin->opts->command eq 'check_sslcert') {
	check_sslcert();
} elsif ($plugin->opts->command eq 'dump_stats') {
	dump_stats();
} elsif ($plugin->opts->command eq 'dump_conf') {
	dump_conf();
} elsif ($plugin->opts->command eq 'dump_vserver') {
	dump_vserver();
} else {
	$plugin->nagios_die('unkown argument for parameter -C (command)', CRITICAL);
}

my $result = Nitro::_logout($session);

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

sub check_vserver
{
        if (!defined $plugin->opts->identifier) {
                $plugin->nagios_die('command requires identifier parameter', CRITICAL);
        }

	my $nitro_request = Nitro::_get_stats($session, $plugin->opts->identifier, $plugin->opts->filter);

	my $state_up     = '';
	my $state_down   = '';
	my $state_unkown = '';
	my $state_oos    = '';

	my $counter_up     = 0;
	my $counter_down   = 0;
	my $counter_unkown = 0;
	my $counter_oos    = 0;
	
	if ($nitro_request->{errorcode} != 0) {
		$plugin->nagios_die($nitro_request->{message}, CRITICAL);
	}

	if ($plugin->opts->verbose) {
		print Dumper($nitro_request);
	}
	$nitro_request = $nitro_request->{$plugin->opts->identifier};
	foreach my $nitro_request (@{$nitro_request}) {
		# NetScaler API Bug: returns "ENABLED" instead of "UP" when requesting services/servicegroups
		if ($nitro_request->{state} eq "UP" || $nitro_request->{state} eq "ENABLED") {
			$counter_up++;
		}
		elsif ($nitro_request->{state} eq "DOWN") {
			$counter_down++;
			$plugin->add_message(CRITICAL, $nitro_request->{name} . " down");
		}
		elsif ($nitro_request->{state} eq "OUT OF SERVICE") {
			$counter_oos++;
			$plugin->add_message(CRITICAL, $nitro_request->{name} . " oos");
		}
		elsif ($nitro_request->{state} eq "UNKOWN") {
			$counter_unkown++;
			$plugin->add_message(CRITICAL, $nitro_request->{name} . " unkown");				
		} else {
			$counter_unkown++;
			$plugin->add_message(CRITICAL, $nitro_request->{name} . " unknown");				
		}
	}		
	my ($code, $message) = $plugin->check_messages;
		
	my $stats = $counter_up . " up, " . $counter_down . " down, " . $counter_oos . " oos, " . $counter_unkown . " unkown";
	
	$plugin->add_perfdata(
		label     => "up",
		value     => $counter_up,
		min       => 0,
		max       => undef,
		threshold => undef,
   	);
        $plugin->add_perfdata(
                label     => "down",
                value     => $counter_down,
                min       => 0,
                max       => undef,
                threshold => undef,
        );
        $plugin->add_perfdata(
                label     => "oos",
                value     => $counter_oos,
                min       => 0,
                max       => undef,
                threshold => undef,
        );
        $plugin->add_perfdata(
                label     => "unkown",
                value     => $counter_unkown,
                min       => 0,
                max       => undef,
                threshold => undef,
        );
		
	$plugin->nagios_exit($code, "NetScaler " . $plugin->opts->identifier . " " . $message . $stats);

}

sub check_string
{
        if (!defined $plugin->opts->filter) {
                $plugin->nagios_die('command requires parameter for filter', CRITICAL);
        }

        if (!defined $plugin->opts->warning || !defined $plugin->opts->critical) {
                $plugin->nagios_die('command requires parameter for warning and critical', CRITICAL);
        }

	my $nitro_request = Nitro::_get_stats($session, $plugin->opts->identifier);

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
        if (!defined $plugin->opts->filter) {
                $plugin->nagios_die('command requires parameter for filter', CRITICAL);
        }

        if (!defined $plugin->opts->warning || !defined $plugin->opts->critical) {
                $plugin->nagios_die('command requires parameter for warning and critical', CRITICAL);
        }

        my $nitro_request = Nitro::_get_stats($session, $plugin->opts->identifier);

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
	if (!defined $plugin->opts->filter) {
		$plugin->nagios_die('command requires parameter for filter', CRITICAL);
	}

	if (!defined $plugin->opts->warning || !defined $plugin->opts->critical) {
		$plugin->nagios_die('command requires parameter for warning and critical', CRITICAL);
	}

	my $nitro_request = Nitro::_get_stats($session, $plugin->opts->identifier);

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
	if (!defined $plugin->opts->filter) {
		$plugin->nagios_die('command requires parameter for filter', CRITICAL);
	}

	if (!defined $plugin->opts->warning || !defined $plugin->opts->critical) {
		$plugin->nagios_die('command requires parameter for warning and critical', CRITICAL);
	}

	my $nitro_request = Nitro::_get_stats($session, $plugin->opts->identifier);
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
        if (!defined $plugin->opts->warning || !defined $plugin->opts->critical) {
                $plugin->nagios_die('command requires parameter for warning and critical', CRITICAL);
        }

        my $nitro_request = Nitro::_get($session, $plugin->opts->identifier, $plugin->opts->filter);
        if ($nitro_request->{errorcode} != 0) {
                $plugin->nagios_die($nitro_request->{message}, CRITICAL);
        }

        if ($plugin->opts->verbose) {
                print Dumper($nitro_request);
        }

        $nitro_request = $nitro_request->{$plugin->opts->identifier};

        foreach $nitro_request (@{$nitro_request}) {
                if ($nitro_request->{daystoexpiration} <= $plugin->opts->critical) {
                        $plugin->add_message(CRITICAL, $nitro_request->{certkey} . " expires in " . $nitro_request->{daystoexpiration} . " days;");
		} elsif ($nitro_request->{daystoexpiration} <= $plugin->opts->warning) {
                        $plugin->add_message(WARNING, $nitro_request->{certkey} . " expires in " . $nitro_request->{daystoexpiration} . " days;");
                } else {
                        # OK, write some stats...
                }
        }

        my ($code, $message) = $plugin->check_messages;

	$plugin->nagios_exit($code, "NetScaler SSLCerts " . $message);
}

sub dump_stats
{
	my $nitro_request = Nitro::_get_stats($session, $plugin->opts->identifier, $plugin->opts->filter);
        if ($nitro_request->{errorcode} != 0) {
                $plugin->nagios_die($nitro_request->{message}, CRITICAL);
        }
	print Dumper($nitro_request);
}

sub dump_conf
{
        my $nitro_request = Nitro::_get($session, $plugin->opts->identifier, $plugin->opts->filter);
        if ($nitro_request->{errorcode} != 0) {
                $plugin->nagios_die($nitro_request->{message}, CRITICAL);
        }
        print Dumper($nitro_request);
}

sub dump_vserver
{
	my $nitro_request = Nitro::_get_stats($session, $plugin->opts->identifier, $plugin->opts->filter);
        if ($nitro_request->{errorcode} != 0) {
                $plugin->nagios_die($nitro_request->{message}, CRITICAL);
        }
        print Dumper($nitro_request);
}
