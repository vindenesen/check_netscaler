#!/usr/bin/env bats
# Travis CI Test for check_netscaler.pl
# https://github.com/slauger/check_netscaler

# do some basic plugin tests
@test "check_netscaler with command sslcert" {
  run ./check_netscaler.pl -H ${NETSCALER_IP} -C sslcert
  echo "status = ${status}"
  echo "output = ${output}"
  [ ${status} -eq 0 ]
}
@test "check_netscaler with command interfaces" {
  run ./check_netscaler.pl -H ${NETSCALER_IP} -C interfaces
  echo "status = ${status}"
  echo "output = ${output}"
  [ ${status} -eq 0 ]
}
@test "check_netscaler with command nsconfig" {
  run ./check_netscaler.pl -H ${NETSCALER_IP} -C nsconfig
  echo "status = ${status}"
  echo "output = ${output}"
  [ ${status} -eq 0 ]
}
@test "check_netscaler with command hastatus" {
  run ./check_netscaler.pl -H ${NETSCALER_IP} -C hastatus
  echo "status = ${status}"
  echo "output = ${output}"
  [ ${status} -eq 0 ]
}

@test "check_netscaler with command system_memusagepcnt" {
  run ./check_netscaler.pl -H ${NETSCALER_IP} -s -C above -o system -n memusagepcnt -w 75 -c 80
  echo "status = ${status}"
  echo "output = ${output}"
  [ ${status} -eq 0 ]
}
@test "check_netscaler with command system_cpuusagepcnt" {
  run ./check_netscaler.pl -H ${NETSCALER_IP} -s -C above -o system -n cpuusagepcnt,mgmtcpuusagepcnt -w 75 -c 80
  echo "status = ${status}"
  echo "output = ${output}"
  [ ${status} -eq 0 ]
}
@test "check_netscaler with command system_diskperusage" {
  run ./check_netscaler.pl -H ${NETSCALER_IP} -s -C above -o system -n disk0perusage,disk1perusage -w 75 -c 80
  echo "status = ${status}"
  echo "output = ${output}"
  [ ${status} -eq 0 ]
}

# test state all objects at once
@test "check_netscaler with command state_lbvserver" {
  run ./check_netscaler.pl -H ${NETSCALER_IP} -C state -o lbvserver
  echo "status = ${status}"
  echo "output = ${output}"
  [ ${status} -eq 0 ]
}
@test "check_netscaler with command state_csvserver" {
  run ./check_netscaler.pl -H ${NETSCALER_IP} -C state -o csvserver
  echo "status = ${status}"
  echo "output = ${output}"
  [ ${status} -eq 0 ]
}
@test "check_netscaler with command state_service" {
  run ./check_netscaler.pl -H ${NETSCALER_IP} -C state -o service
  echo "status = ${status}"
  echo "output = ${output}"
  [ ${status} -eq 0 ]
}
@test "check_netscaler with command state_servicegroup" {
  run ./check_netscaler.pl -H ${NETSCALER_IP} -C state -o servicegroup
  echo "status = ${status}"
  echo "output = ${output}"
  [ ${status} -eq 0 ]
}
@test "check_netscaler with command state_server" {
  run ./check_netscaler.pl -H ${NETSCALER_IP} -C state -o server
  echo "status = ${status}"
  echo "output = ${output}"
  [ ${status} -eq 0 ]
}

# test state of single objects
@test "check_netscaler with command state_lbvserver and single object" {
  run ./check_netscaler.pl -H ${NETSCALER_IP} -C state -o lbvserver -n vs_lb_http_web1
  echo "status = ${status}"
  echo "output = ${output}"
  [ ${status} -eq 0 ]
}
@test "check_netscaler with command state_csvserver and single object" {
  run ./check_netscaler.pl -H ${NETSCALER_IP} -C state -o csvserver -n vs_cs_http_web1
  echo "status = ${status}"
  echo "output = ${output}"
  [ ${status} -eq 0 ]
}
@test "check_netscaler with command state_service and single object" {
  run ./check_netscaler.pl -H ${NETSCALER_IP} -C state -o service -n svc_http_web1
  echo "status = ${status}"
  echo "output = ${output}"
  [ ${status} -eq 0 ]
}
@test "check_netscaler with command state_servicegroup and single object" {
  run ./check_netscaler.pl -H ${NETSCALER_IP} -C state -o servicegroup -n sg_http_web1
  echo "status = ${status}"
  echo "output = ${output}"
  [ ${status} -eq 0 ]
}
@test "check_netscaler with command state_server and single object" {
  run ./check_netscaler.pl -H ${NETSCALER_IP} -C state -o server -n srv_web1
  echo "status = ${status}"
  echo "output = ${output}"
  [ ${status} -eq 0 ]
}
