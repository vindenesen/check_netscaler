#!/usr/bin/env bats
# Travis CI Test for check_netscaler.pl
# https://github.com/slauger/check_netscaler

# do some basic plugin tests
@test "check_netscaler with command sslcert"
{
  result=$(./check_netscaler.pl -v -H ${CIP} -C sslcert)
  [ ${result} -eq 0 ]
}
@test "check_netscaler with command interfaces"
{
  result=$(./check_netscaler.pl -v -H ${CIP} -C interfaces)
  [ ${result} -eq 0 ]
}
@test "check_netscaler with command nsconfig"
{
  result=$(./check_netscaler.pl -v -H ${CIP} -C nsconfig)
  [ ${result} -eq 0 ]
}
@test "check_netscaler with command hastatus"
{
  result=$(./check_netscaler.pl -v -H ${CIP} -C hastatus)
  [ ${result} -eq 0 ]
}

@test "check_netscaler with command system_memusagepcnt"
{
  result=$(./check_netscaler.pl -v -H ${CIP} -s -C above -o system -n memusagepcnt -w 75 -c 80)
  [ ${result} -eq 0 ]
}
@test "check_netscaler with command system_cpuusagepcnt"
{
  result=$(./check_netscaler.pl -v -H ${CIP} -s -C above -o system -n cpuusagepcnt,mgmtcpuusagepcnt -w 75 -c 80)
  [ ${result} -eq 0 ]
}
@test "check_netscaler with command system_diskperusage"
{
  result=$(./check_netscaler.pl -v -H ${CIP} -s -C above -o system -n disk0perusage,disk1perusage -w 75 -c 80)
  [ ${result} -eq 0 ]
}

# test state all objects at once
@test "check_netscaler with command state_lbvserver"
{
  result=$(./check_netscaler.pl -v -H ${CIP} -C state -o lbvserver)
  [ ${result} -eq 0 ]
}
@test "check_netscaler with command state_csvserver"
{
  result=$(./check_netscaler.pl -v -H ${CIP} -C state -o csvserver)
  [ ${result} -eq 0 ]
}
@test "check_netscaler with command state_service"
{
  result=$(./check_netscaler.pl -v -H ${CIP} -C state -o service)
  [ ${result} -eq 0 ]
}
@test "check_netscaler with command state_servicegroup"
{
  result=$(./check_netscaler.pl -v -H ${CIP} -C state -o servicegroup)
  [ ${result} -eq 0 ]
}
@test "check_netscaler with command state_server"
{
  result=$(./check_netscaler.pl -v -H ${CIP} -C state -o server)
  [ ${result} -eq 0 ]
}

# test state of single objects
@test "check_netscaler with command state_lbvserver_single"
{
  result=$(./check_netscaler.pl -v -H ${CIP} -C state -o lbvserver -n vs_lb_http_web1)
  [ ${result} -eq 0 ]
}
@test "check_netscaler with command state_csvserver_single"
{
  result=$(./check_netscaler.pl -v -H ${CIP} -C state -o csvserver -n vs_cs_http_web1)
  [ ${result} -eq 0 ]
}
@test "check_netscaler with command state_service"
{
  result=$(./check_netscaler.pl -v -H ${CIP} -C state -o service -n svc_http_web1)
  [ ${result} -eq 0 ]
}
@test "check_netscaler with command state_servicegroup"
{
  result=$(./check_netscaler.pl -v -H ${CIP} -C state -o servicegroup -n sg_http_web1)
  [ ${result} -eq 0 ]
}
@test "check_netscaler with command state_server"
{
  result=$(./check_netscaler.pl -v -H ${CIP} -C state -o server -n srv_web1)
  [ ${result} -eq 0 ]
}
