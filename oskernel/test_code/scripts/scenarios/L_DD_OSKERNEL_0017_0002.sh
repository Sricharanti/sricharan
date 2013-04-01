#!/bin/bash -x

source config 

#Preparations, e.g. removing any locks at console port
sudo rm -f /var/lock/LCK..tty"`echo $CONSOLE_PORT  | egrep -o "USB."`"
sudo chown nobody.root $CONSOLE_PORT

echo "Kernel boot time testing"

`dirname $0`/0017_0002.expect | tee log
time=$(cat log | grep --text "kernel_time:" | sed "s/kernel_time://")
echo $time
[ -n "$time" ] && [ "$time" -le 9400 ] && echo "Test PASS" || echo "Test FAIL"
rm log
