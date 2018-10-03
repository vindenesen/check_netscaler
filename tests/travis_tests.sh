#!/bin/bash
# Travis CI Test for check_netscaler.pl
# https://github.com/slauger/check_netscaler

function deploy_nsconfig
{
  # auto accept ssh host key
  sshpass -p nsroot ssh -o StrictHostKeyChecking=no nsroot@${CIP} hostname

  # configure netscaler cpx
  sshpass -p nsroot scp tests/ns.conf nsroot@${CIP}:/home/nsroot/ns.conf
  sshpass -p nsroot ssh nsroot@${CIP} "/var/netscaler/bins/cli_script.sh /home/nsroot/ns.conf"
}

deploy_nsconfig
