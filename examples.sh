#!/bin/bash

# default ipaddr 
if [ "${1}" = "" ];
then
	echo "Syntax: $0 <hostname> [<username>] [<password>]"
	exit 1
else
	IPADDR="${1}"
fi

# default username
if [ "${2}" = "" ];
then
	USERNAME="nsroot"
else
	USERNAME=${2}
fi

# default password
if [ "${3}" = "" ];
then
        PASSWORD="nsroot"
else
        PASSWORD=${3}
fi

# NetScaler::SSLCerts
./check_netscaler.pl -H ${IPADDR} -U ${USERNAME} -P ${PASSWORD} -C check_sslcert -I sslcertkey -w 30 -c 10

# NetScaler::VPNvServer::State
./check_netscaler.pl -H ${IPADDR} -U ${USERNAME} -P ${PASSWORD} -C check_vserver -I vpnvserver

# NetScaler::LBvServer::State
./check_netscaler.pl -H ${IPADDR} -U ${USERNAME} -P ${PASSWORD} -C check_vserver -I lbvserver

# NetScaler::GSLBvServer::State
./check_netscaler.pl -H ${IPADDR} -U ${USERNAME} -P ${PASSWORD} -C check_vserver -I gslbvserver

# NetScaler:::AAAvServer::State
./check_netscaler.pl -H ${IPADDR} -U ${USERNAME} -P ${PASSWORD} -C check_vserver -I authenticationvserver

# NetScaler:::CSvServer::State
./check_netscaler.pl -H ${IPADDR} -U ${USERNAME} -P ${PASSWORD} -C check_vserver -I csvserver

# NetScaler::SSLvServer::State
#./check_netscaler.pl -H ${IPADDR} -U ${USERNAME} -P ${PASSWORD} -C check_vserver -I sslvserver

# NetScaler::System::Memory
./check_netscaler.pl -H ${IPADDR} -U ${USERNAME} -P ${PASSWORD} -C check_threshold_above -I system -F memusagepcnt -w 75 -c 80

# NetScaler::System::CPU
./check_netscaler.pl -H ${IPADDR} -U ${USERNAME} -P ${PASSWORD} -C check_threshold_above -I system -F cpuusagepcnt -w 75 -c 80

# NetScaler::System::CPU::MGMT
./check_netscaler.pl -H ${IPADDR} -U ${USERNAME} -P ${PASSWORD} -C check_threshold_above -I system -F mgmtcpuusagepcnt -w 75 -c 80

# NetScaler::System::Disk0
./check_netscaler.pl -H ${IPADDR} -U ${USERNAME} -P ${PASSWORD} -C check_threshold_above -I system -F disk0perusage -w 75 -c 80

# NetScaler::System::Disk1
./check_netscaler.pl -H ${IPADDR} -U ${USERNAME} -P ${PASSWORD} -C check_threshold_above -I system -F disk1perusage -w 75 -c 80

# NetScaler::HA::Status
./check_netscaler.pl -H ${IPADDR} -U ${USERNAME} -P ${PASSWORD} -C check_string_not -I hanode -F hacurstatus -w YES -c YES

# NetScaler::HA::State
./check_netscaler.pl -H ${IPADDR} -U ${USERNAME} -P ${PASSWORD} -C check_string_not -I hanode -F hacurstate -w UP -c UP
