#!/bin/bash

# default ipaddr 
if [ "${1}" = "" ];
then
	echo "Syntax: $0 <hostname> [<username>] [<password>] [(bool) ssl]"
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

# enable ssl
if [ "${4}" = "" ];
then
	SSL=""
else
	SSL="-s"
fi

# NetScaler::SSLCerts
./check_netscaler.pl -H ${IPADDR} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C sslcerts -w 30 -c 10

# NetScaler::VPNvServer::State
./check_netscaler.pl -H ${IPADDR} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C state -o vpnvserver

# NetScaler::LBvServer::State
./check_netscaler.pl -H ${IPADDR} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C state -o lbvserver

# NetScaler::GSLBvServer::State
./check_netscaler.pl -H ${IPADDR} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C state -o gslbvserver

# NetScaler:::AAAvServer::State
./check_netscaler.pl -H ${IPADDR} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C state -o authenticationvserver

# NetScaler:::CSvServer::State
./check_netscaler.pl -H ${IPADDR} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C state -o csvserver

# NetScaler::SSLvServer::State
#./check_netscaler.pl -H ${IPADDR} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C state -o sslvserver

# NetScaler::System::Memory
./check_netscaler.pl -H ${IPADDR} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C above -o system -n memusagepcnt -w 75 -c 80

# NetScaler::System::CPU
./check_netscaler.pl -H ${IPADDR} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C above -o system -n cpuusagepcnt -w 75 -c 80

# NetScaler::System::CPU::MGMT
./check_netscaler.pl -H ${IPADDR} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C above -o system -n mgmtcpuusagepcnt -w 75 -c 80

# NetScaler::System::Disk0
./check_netscaler.pl -H ${IPADDR} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C above -o system -n disk0perusage -w 75 -c 80

# NetScaler::System::Disk1
./check_netscaler.pl -H ${IPADDR} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C above -o system -n disk1perusage -w 75 -c 80

# NetScaler::HA::Status
./check_netscaler.pl -H ${IPADDR} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C string_not -o hanode -n hacurstatus -w YES -c YES

# NetScaler::HA::State
./check_netscaler.pl -H ${IPADDR} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C string_not -o hanode -n hacurstate -w UP -c UP
