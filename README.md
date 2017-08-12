# check_netscaler Nagios Plugin

A Nagios Plugin written for the Citrix NetScaler Application Delivery Controller. It's based on Perl (Nagios::Plugin) and using the the NITRO REST API. No need for SNMP.

Currently the plugin has the following subcommands:


| command | description |
---       | --- | 
**state**              | check the current service state of vservers (e.g. lb, vpn, gslb), services and service groups
**string, string_not** | check if a string exists in the api response or not (e.g. HA or cluster status)
**above, below**       | check if a value is above/below a threshold (e.g. traffic limits, concurrent connections)
**sslcert**            | check the lifetime for installed ssl certificates
**nsconfig**           | check for configuration changes which are not saved to disk
**license**            | check the expiry date of a local installed license file
**server**             | check status of Load Balancing Servers
**staserver**          | check if configured STA (secure ticket authority) servers are available
**servicegroup**       | check the state of a servicegroup and its members
**hwinfo**             | just print information about the Netscaler itself
**interfaces**         | check state of all interfaces and add performance data for each interface
**performancedata**    | gather performancedata from all sorts of API endpoints
**debug**              | debug command, print all data for a endpoint

This plugin works with VPX, MPX, SDX and CPX NetScaler Appliances. The api responses may differ by build, appliance type and your installed license.

The plugin supports performance data for the commands state and the above or below threshold checks. Also there is a performancedata command to gather information from your NetScaler.

Example configurations for Nagios and Icinga 2 can be found in the examples directory of this repository.

Feedback and feature requests are appreciated. Just create an issue on GitHub or send me a pull request.

If you looking for a plugin to test your NetScaler Gateway vServer and Storefront see also [check_netscaler_gateway](https://github.com/slauger/check_netscaler_gateway).

## Installation

On a Enterprise Linux machine (CentOS, RHEL) execute the following commands to install all Perl dependencies (Nagios::Plugin, LWP, JSON):

```
yum install perl-libwww-perl perl-JSON perl-Nagios-Plugin perl-Time-Piece perl-Data-Dumper
```

If you want to connect to your NetScaler with SSL/HTTPS you should also install the LWP HTTPS package.

```
yum install perl-LWP-Protocol-https
```

## Usage Examples

### Check status of vServers

```
# NetScaler::LBvServer
./check_netscaler.pl -H ${IPADDR} -s -C state -o lbvserver

# NetScaler::LBvServer::Website
./check_netscaler.pl -H ${IPADDR} -s -C state -o lbvserver -n vs_lb_http_webserver

# NetScaler::VPNvServer
./check_netscaler.pl -H ${IPADDR} -s -C state -o vpnvserver

# NetScaler::GSLBvServer
./check_netscaler.pl -H ${IPADDR} -s -C state -o gslbvserver

# NetScaler::AAAvServer
./check_netscaler.pl -H ${IPADDR} -s -C state -o authenticationvserver

# NetScaler::CSvServer
./check_netscaler.pl -H ${IPADDR} -s -C state -o csvserver

# NetScaler::SSLvServer (obsolet and replaced by lbvserver for newer builds)
./check_netscaler.pl -H ${IPADDR} -s -C state -o sslvserver
```

### Check status of services

```
# NetScaler::Services
./check_netscaler.pl -H ${IPADDR} -s -C state -o service

# NetScaler::Services::Webserver
./check_netscaler.pl -H ${IPADDR} -s -C state -o service -n svc_webserver
```

### Check status of service groups

```
# NetScaler::Servicegroups
./check_netscaler.pl -H ${IPADDR} -s -C state -o servicegroup

# NetScaler::Servicegroups::Webservers
./check_netscaler.pl -H ${IPADDR} -s -C state -o servicegroup -n sg_webservers
```

### Check status and quorum of a service group

define member quorum (in percent) with warning and critical values

```
# NetScaler::Servicegroup::Webservers
./check_netscaler.pl -H ${IPADDR} -s -C servicegroup -n sg_webservers -w 75 -c 50
```

### Check if Load Balancing servers are enabled

```
# NetScaler::Server
./check_netscaler.pl -H ${IPADDR} -s -C server

# NetScaler::Server
./check_netscaler.pl -H ${IPADDR} -s -C server -n web01.example.com
```

### Check system health

```
# NetScaler::Memory
./check_netscaler.pl -H ${IPADDR} -s -C above -o system -n memusagepcnt -w 75 -c 80

# NetScaler::CPU
./check_netscaler.pl -H ${IPADDR} -s -C above -o system -n cpuusagepcnt -w 75 -c 80

# NetScaler::CPUMGMT
./check_netscaler.pl -H ${IPADDR} -s -C above -o system -n mgmtcpuusagepcnt -w 75 -c 80

# NetScaler::Disk0
./check_netscaler.pl -H ${IPADDR} -s -C above -o system -n disk0perusage -w 75 -c 80

# NetScaler::Disk1
./check_netscaler.pl -H ${IPADDR} -s -C above -o system -n disk1perusage -w 75 -c 80
```

### Check high availability status

```
# NetScaler::HA::Status
./check_netscaler.pl -H ${IPADDR} -s -C string_not -o hanode -n hacurstatus -w YES -c YES

# NetScaler::HA::State
./check_netscaler.pl -H ${IPADDR} -s -C string_not -o hanode -n hacurstate -w UP -c UP
```

### Check expiration of installed ssl certificates

```
# NetScaler::Certs
./check_netscaler.pl -H ${IPADDR} -s -C sslcert -w 30 -c 10

# NetScaler::Certs::Wildcard
./check_netscaler.pl -H ${IPADDR} -s -C sslcert -n wildcard.example.com -w 30 -c 10
```

### Check for unsaved configuration changes

```
# NetScaler::Config
./check_netscaler.pl -H ${IPADDR} -s -C nsconfig
```

### Check the expiry date of a local license file

The license file must be placed in `/nsconfig/license` and the filename must be given as objectname.
Also the NITRO user needs permissions to access the filesystem directly (NITRO command systemfile).

```
# NetScaler::License
./check_netscaler.pl -H ${IPADDR} -s -C license -n FID_4c9a2c7e_14292ea2df2_2a97.lic -w 30 -c 10
```

### Check if STA servers are working

```
# NetScaler::STA
./check_netscaler.pl -H ${IPADDR} -s -C staserver

# NetScaler::STA::vs_vpn_gateway
./check_netscaler.pl -H ${IPADDR} -s -C staserver -n vs_vpn_gateway
```

### Get information about the netscaler

```
# NetScaler::HWInfo
./check_netscaler.pl -H ${IPADDR} -s -C hwinfo
```

### Check status of all network interfaces

```
# NetScaler::Interfaces
./check_netscaler.pl -H ${IPADDR} -s -C interfaces
```

### Request performance data

All fields must be defined via "-n" option and be seperated with a comma.

```
# NetScaler::Performancedata on Cache hit/misses
./check_netscaler.pl -H ${IPADDR} -s -C performancedata -o ns -n cachetothits,cachetotmisses

# NetScaler::Performancedata on tcp connections
./check_netscaler.pl -H ${IPADDR} -s -C performancedata -o ns -n tcpcurclientconn,tcpcurclientconnestablished,tcpcurserverconn,tcpcurserverconnestablished

# NetScaler::Performancedata on network interfaces
./check_netscaler.pl -H ${IPADDR} -s -C performancedata -o Interface -n id.totrxbytes

# NetScaler::Current user sessions
./check_netscaler.pl -H ${IPADDR} -s -C performancedata -o aaa -n aaacuricasessions,aaacuricaonlyconn

# find more object names to check out for object type "ns"
/check_netscaler.pl -H ${IPADDR} -s -C debug -o ns
```

[Global counters](https://docs.citrix.com/en-us/netscaler/12/nitro-api/nitro-rest/nitro-rest-usage-scenarios/view-individual-counter-info.html) can be accessed as follows (NetScaler 12.0 and newer).

```
./check_netscaler.pl -H ${IPADDR} -s -C performancedata -n http_tot_Requests,http_tot_Responses -x 'args=counters:http_tot_Requests;http_tot_Responses'
```

For more interesting performance data object types see the following API methods.

- ns
- cache
- protocolhttp
- protocolip
- protocoltcp

## Debug command

```
# Print all LB vServers (stat endpoint)
./check_netscaler.pl -H ${IPADDR} -s -C debug -o lbvserver

# Print all LB vServers (config endpoint)
./check_netscaler.pl -H ${IPADDR} -s -C debug -o lbvserver -e config
```

## Configuration File

The plugin uses the Nagios::Plugin Libary, so you can use --extra-opts and seperate the login crendetials from your nagios configuration.

```
define command {
  command_name check_netscaler_vserver
  command_line $USER5$/3rdparty/check_netscaler/check_netscaler.pl -H $HOSTADDRESS$ -s --extra-opts=netscaler@$USER11$/plugins.ini -C state -n '$ARG1$'
}
```

```
[netscaler]
username=nagios
password=password
```

## Authors
- [slauger](https://github.com/slauger)

## Contributors
- [macampo](https://github.com/macampo)
- [Velociraptor85](https://github.com/Velociraptor85)
- [bb-ricardo](https://github.com/bb-ricardo)

## NITRO API Documentation

You will find a full documentation about the NITRO API on your NetScaler Appliance in the "Download" area.

http://NSIP/nitro-rest.tgz (where NSIP is the IP address of your NetScaler appliance).

## Tested Firmware

Tested with NetScaler 10.5, 11.0, 11.1 and 12.0. The plugin should work with all available firmware builds.

## Changelog

See [CHANGELOG](CHANGELOG.md)
