#!/bin/bash
# Travis CI Test Script for check_netscaler.pl
# https://github.com/slauger/check_netscaler

# source bash testing framework
source tests/bash_test_tools

# get ipaddress from container id
CID=$(docker ps | grep netscalercpx | awk '{print $1}')
CIP=$(docker inspect ${CID} | grep IPAddress | cut -d '"' -f 4 | tail -n1)

# setup unit tests
function setup
{
  # auto accept ssh host key
  sshpass -p nsroot ssh -o StrictHostKeyChecking=no nsroot@${CIP} hostname

  # configure netscaler cpx
  sshpass -p nsroot scp tests/ns.conf nsroot@${CIP}:/home/nsroot/ns.conf
  sshpass -p nsroot ssh nsroot@${CIP} "/var/netscaler/bins/cli_script.sh /home/nsroot/ns.conf"
}

# teardown unit tests
function teardown
{
  return
}

# do some basic plugin tests
function test_sslcert
{
  run "./check_netscaler.pl -v -H ${CIP} -C sslcert"
  assert_success
}
function test_interfaces
{
  run "./check_netscaler.pl -v -H ${CIP} -C interfaces"
  assert_success
}
function test_nsconfig
{
  run "./check_netscaler.pl -v -H ${CIP} -C nsconfig"
  assert_success
}
function test_hastatus
{
  run "./check_netscaler.pl -v -H ${CIP} -C hastatus"
  assert_success
}

# fails on vpx instances
#run "./check_netscaler.pl -v -H ${CIP} -C hwinfo

function test_system_memusagepcnt
{
  run "./check_netscaler.pl -v -H ${CIP} -s -C above -o system -n memusagepcnt -w 75 -c 80"
}
function test_system_cpuusagepcnt
{
  run "./check_netscaler.pl -v -H ${CIP} -s -C above -o system -n cpuusagepcnt,mgmtcpuusagepcnt -w 75 -c 80"
}
function test_system_diskperusage
{
  run "./check_netscaler.pl -v -H ${CIP} -s -C above -o system -n disk0perusage,disk1perusage -w 75 -c 80"
}

# test state all objects at once
function test_state_lbvserver
{
  run "./check_netscaler.pl -v -H ${CIP} -C state -o lbvserver"
}
function test_state_csvserver
{
  run "./check_netscaler.pl -v -H ${CIP} -C state -o csvserver"
}
function test_state_service
{
  run "./check_netscaler.pl -v -H ${CIP} -C state -o service"
}
function test_state_servicegroup
{
  run "./check_netscaler.pl -v -H ${CIP} -C state -o servicegroup"
}
function test_state_server
{
  run "./check_netscaler.pl -v -H ${CIP} -C state -o server"
}

# test state of single objects
function test_state_lbvserver_single
{
  run "./check_netscaler.pl -v -H ${CIP} -C state -o lbvserver -n vs_lb_http_web1"
}
function test_state_csvserver_single
{
  run "./check_netscaler.pl -v -H ${CIP} -C state -o csvserver -n vs_cs_http_web1"
}
function test_state_service
{
  run "./check_netscaler.pl -v -H ${CIP} -C state -o service -n svc_http_web1"
}
function test_state_servicegroup
{
  run "./check_netscaler.pl -v -H ${CIP} -C state -o servicegroup -n sg_http_web1"
}
function test_state_server
{
  run "./check_netscaler.pl -v -H ${CIP} -C state -o server -n srv_web1"
}

# start testrunner
testrunner
