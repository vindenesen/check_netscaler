#!/bin/bash

if [ ! -f "${1}" ]; then
  echo "ERROR: config file not found or not readable"
  echo ""
  echo "Syntax: $0 <config.ini>"
  echo ""
  echo "Configuration example:"
  echo ""
  echo "  [netscaler]"
  echo "  username=nsroot"
  echo "  password=nsroot"
  echo "  hostname=netscaler01.example.local"
  echo "  ssl=true"
  exit 1
fi

if [ "${2}" != "" ]; then
  section="${2}"
else
  section="netscaler"
fi

echo NetScaler::SSLCerts
./check_netscaler.pl --extra-opts=${section}@${1} -C sslcert -w 30 -c 10
echo

echo NetScaler::NSConfig
./check_netscaler.pl --extra-opts=${section}@${1} -C nsconfig
echo

echo NetScaler::HWInfo
./check_netscaler.pl --extra-opts=${section}@${1} -C hwinfo
echo

echo NetScaler::Interfaces
./check_netscaler.pl --extra-opts=${section}@${1} -C interfaces
echo

echo NetScaler::Perfdata::AAA
./check_netscaler.pl --extra-opts=${section}@${1} -C performancedata -o aaa -n aaacuricasessions,aaacuricaonlyconn
echo

echo NetScaler::VPNvServer::State
./check_netscaler.pl --extra-opts=${section}@${1} -C state -o vpnvserver
echo

echo NetScaler::LBvServer::State
./check_netscaler.pl --extra-opts=${section}@${1} -C state -o lbvserver
echo

echo NetScaler::GSLBvServer::State
./check_netscaler.pl --extra-opts=${section}@${1} -C state -o gslbvserver
echo

echo NetScaler:::AAAvServer::State
./check_netscaler.pl --extra-opts=${section}@${1} -C state -o authenticationvserver
echo

echo NetScaler:::CSvServer::State
./check_netscaler.pl --extra-opts=${section}@${1} -C state -o csvserver
echo

#echo NetScaler::SSLvServer::State
#./check_netscaler.pl --extra-opts=${section}@${1} -C state -o sslvserver
#echo

echo NetScaler::Server
./check_netscaler.pl --extra-opts=${section}@${1} -C server
echo

echo NetScaler::System::Memory
./check_netscaler.pl --extra-opts=${section}@${1} -C above -o system -n memusagepcnt -w 75 -c 80
echo

echo NetScaler::System::CPU
./check_netscaler.pl --extra-opts=${section}@${1} -C above -o system -n cpuusagepcnt -w 75 -c 80
echo

echo NetScaler::System::CPU::MGMT
./check_netscaler.pl --extra-opts=${section}@${1} -C above -o system -n mgmtcpuusagepcnt -w 75 -c 80
echo

echo NetScaler::System::Disk0
./check_netscaler.pl --extra-opts=${section}@${1} -C above -o system -n disk0perusage -w 75 -c 80
echo

echo NetScaler::System::Disk1
./check_netscaler.pl --extra-opts=${section}@${1} -C above -o system -n disk1perusage -w 75 -c 80
echo

echo NetScaler::HA::Status
./check_netscaler.pl --extra-opts=${section}@${1} -C matches_not -o hanode -n hacurstatus -w YES -c YES
echo

echo NetScaler::HA::State
./check_netscaler.pl --extra-opts=${section}@${1} -C matches_not -o hanode -n hacurstate -w UP -c UP
echo


