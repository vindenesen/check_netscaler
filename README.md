# check_netscaler

A Nagios Plugin written in Perl for the Citrix NetScaler. It's based on the the NITRO API.

# Installation

On a CentOS machine execute the following commands to install all dependencies (LWP, JSON):

    yum install perl-libwww-perl perl-JSON

# Usage Examples

    NetScaler::VPNvServer::State
    ./check_netscaler.pl -H  192.168.100.100 -U nsroot -P nsroot -C check_vserver -I vpnvserver

    NetScaler::LBvServer::State
    ./check_netscaler.pl -H  192.168.100.100 -U nsroot -P nsroot-C check_vserver -I lbvserver

    NetScaler::System::Memory
    ./check_netscaler.pl -H  192.168.100.100 -U nsroot -P nsroot -C check_threshold_above -I system -F memusagepcnt -w 75 -c 80

    NetScaler::System::CPU
    ./check_netscaler.pl -H  192.168.100.100 -U nsroot -P nsroot -C check_threshold_above -I system -F cpuusagepcnt -w 75 -c 80

    NetScaler::System::CPU::MGMT
    ./check_netscaler.pl -H  192.168.100.100 -U nsroot -P nsroot -C check_threshold_above -I system -F mgmtcpuusagepcnt -w 75 -c 80

    NetScaler::System::Disk0
    ./check_netscaler.pl -H  192.168.100.100 -U nsroot -P nsroot -C check_threshold_above -I system -F disk0perusage -w 75 -c 80

    NetScaler::System::Disk1
    ./check_netscaler.pl -H  192.168.100.100 -U nsroot -P nsroot -C check_threshold_above -I system -F disk1perusage -w 75 -c 80

    NetScaler::HA::Status
    ./check_netscaler.pl -H  192.168.100.100 -U nsroot -P nsroot -C check_string_not -I hanode -F hacurstatus -w YES -c YES

    NetScaler::HA::State
    ./check_netscaler.pl -H  192.168.100.100 -U nsroot -P nsroot -C check_string_not -I hanode -F hacurstate -w UP -c UP

