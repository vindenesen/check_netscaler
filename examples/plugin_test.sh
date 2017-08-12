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
if [ "${4}" == "true" ];
then
	SSL="-s"
else
	SSL=""
fi

if [ "${5}" = "" ];
then
	PORT=""
else
	PORT="-P ${5}"
fi

echo NetScaler::SSLCerts
./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C sslcert -w 30 -c 10
echo

echo NetScaler::NSConfig
./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C nsconfig
echo

echo NetScaler::HWInfo
./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C hwinfo
echo

echo NetScaler::Interfaces
./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C interfaces
echo

echo NetScaler::Perfdata::AAA
./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C performancedata -o aaa -n aaacuricasessions,aaacuricaonlyconn
echo

echo NetScaler::VPNvServer::State
./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C state -o vpnvserver
echo

echo NetScaler::LBvServer::State
./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C state -o lbvserver
echo

echo NetScaler::GSLBvServer::State
./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C state -o gslbvserver
echo

echo NetScaler:::AAAvServer::State
./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C state -o authenticationvserver
echo

echo NetScaler:::CSvServer::State
./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C state -o csvserver
echo

#echo NetScaler::SSLvServer::State
#./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C state -o sslvserver
#echo

echo NetScaler::Server
./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C server
echo

echo NetScaler::System::Memory
./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C above -o system -n memusagepcnt -w 75 -c 80
echo

echo NetScaler::System::CPU
./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C above -o system -n cpuusagepcnt -w 75 -c 80
echo

echo NetScaler::System::CPU::MGMT
./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C above -o system -n mgmtcpuusagepcnt -w 75 -c 80
echo

echo NetScaler::System::Disk0
./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C above -o system -n disk0perusage -w 75 -c 80
echo

echo NetScaler::System::Disk1
./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C above -o system -n disk1perusage -w 75 -c 80
echo

echo NetScaler::HA::Status
./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C matches_not -o hanode -n hacurstatus -w YES -c YES
echo

echo NetScaler::HA::State
./check_netscaler.pl -H ${IPADDR} ${PORT} ${SSL} -u ${USERNAME} -p ${PASSWORD} -C matches_not -o hanode -n hacurstate -w UP -c UP
echo


