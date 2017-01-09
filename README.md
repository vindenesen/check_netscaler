# check_netscaler Nagios Plugin

A Nagios Plugin written for the Citrix NetScaler Application Delivery Controller. It's based on Perl (Nagios::Plugin) and using the the NITRO REST API. No need for SNMP.

Currently the plugin has the following subcommands:

- **check_vserver:** check the current service state of vservers (e.g. lb, vpn, gslb) and service groups
- **check_string, check_string_not:** check for a specific string in the api response (e.g. HA or cluster status)
- **check_threshold_above, check_threshold_below:** check for a threshold (e.g. traffic limits, concurrent connections)
- **check_sslcert:**: check the lifetime for all installed ssl certificates
- **dump_stats:** debug command, print all data for a stats endpoint
- **dump_conf:** debug command, print all data for a conf endpoint
- **dump_vserver:** debug command, print all vservers

This plugin works with VPX, MPX and SDX NetScaler Appliances. The api responses differ by appliance type and your installed license.

The plugin is in alpha state and feedback and feature requests are appreciated. Performance data is available.

The Nitro.pm by Citrix (released under the Apache License 2.0) is required for using this plugin.

# Installation

On a CentOS/RHEL machine execute the following commands to install all Perl dependencies (Nagios::Plugin, LWP, JSON):

    yum install perl-libwww-perl perl-JSON perl-Nagios-Plugin

Copy the Nitro.pm in the same directory as the check_netscaler.pl file or copy it to you @INC (include path).

# Usage Examples

    NetScaler::VPNvServer::State
    ./check_netscaler.pl -H  192.168.100.100 -C check_vserver -I vpnvserver

    NetScaler::LBvServer::State
    ./check_netscaler.pl -H  192.168.100.100 -C check_vserver -I lbvserver

    NetScaler::System::Memory
    ./check_netscaler.pl -H  192.168.100.100 -C check_threshold_above -I system -F memusagepcnt -w 75 -c 80

    NetScaler::System::CPU
    ./check_netscaler.pl -H  192.168.100.100 -C check_threshold_above -I system -F cpuusagepcnt -w 75 -c 80

    NetScaler::System::CPU::MGMT
    ./check_netscaler.pl -H  192.168.100.100 -C check_threshold_above -I system -F mgmtcpuusagepcnt -w 75 -c 80

    NetScaler::System::Disk0
    ./check_netscaler.pl -H  192.168.100.100 -C check_threshold_above -I system -F disk0perusage -w 75 -c 80

    NetScaler::System::Disk1
    ./check_netscaler.pl -H  192.168.100.100 -C check_threshold_above -I system -F disk1perusage -w 75 -c 80

    NetScaler::HA::Status
    ./check_netscaler.pl -H  192.168.100.100 -C check_string_not -I hanode -F hacurstatus -w YES -c YES

    NetScaler::HA::State
    ./check_netscaler.pl -H  192.168.100.100 -C check_string_not -I hanode -F hacurstate -w UP -c UP

# Configuration File
The plugin uses the Nagios::Plugin Libary, so you can use --extra-opts and seperate the login crendetials from your nagios configuration.

e.g.

```
define command {
  command_name check_netscaler_vserver
  command_line $USER5$/3rdparty/check_netscaler/check_netscaler.pl -H $HOSTADDRESS$ --extra-opts=netscaler@$USER11$/plugins.ini -C check_vserver -I '$ARG1$'
}
```

```
[netscaler]
username=nagios
password=password
```

# NITRO API Documentation

You will find a full documentation about the NITRO API on your NetScaler Appliance in the "Download" area.

http://NSIP/nitro-rest.tgz (where NSIP is the IP address of your NetScaler appliance). 

# Tested Firmware

Tested with NetScaler 10.5, 11.0 and 11.1. The plugin should work with all available releases.
