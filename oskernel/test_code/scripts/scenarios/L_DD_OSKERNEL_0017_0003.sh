#!/bin/bash -x

source config

#Preparations, e.g. removing any locks at console port
sudo rm -f /var/lock/LCK..tty"`echo $CONSOLE_PORT  | egrep -o "USB."`"
sudo chown nobody.root $CONSOLE_PORT

echo "Kernel boot time testing"

sleep 2
`dirname $0`/0017_0003.expect | tee log
time=$(cat log | grep --text "fs_time:" | sed "s/fs_time://")
echo $time
[ -n "$time" ] && [ "$time" -le 17000 ] && echo "Test PASS" || echo "Test FAIL"
rm log
