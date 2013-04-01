#!/bin/bash -x

source config

#Preparations, e.g. removing any locks at console port
sudo rm -f /var/lock/LCK..tty"`echo $CONSOLE_PORT  | egrep -o "USB."`"
sudo chown nobody.root $CONSOLE_PORT

echo "Bootloader boot time testing"

`dirname $0`/0017_0001.expect | tee log
time=$(cat log | grep --text "boot_time:" | sed "s/boot_time://")
echo $time
[ -n "$time" ] && [ "$time" -le 10000 ] && echo "Test PASS" || echo "Test FAIL"
rm log
