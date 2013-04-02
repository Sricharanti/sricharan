#!/bin/bash
error_val=0

source config
echo $DEVICE_SERIAL

i=1000
j=0
tot=$i
adb=`whereis adb | cut -d ":" -f2`
echo $adb

start=`date "+%s"`
while [ $i -gt 0 ]
do
	now=`date "+%s"`
	delt=`expr $now - $start`
	iter=`expr $tot - $i`
	echo "test: $iter (start=$start, now=$now, delta=$delt)"
	$adb -s $DEVICE_SERIAL wait-for-device
	echo "adb waited"
	sleep 1
	$adb -s $DEVICE_SERIAL root
	echo "adb rooted"
	sleep 5
	$adb -s $DEVICE_SERIAL remount
	echo "adb remounted"
	sleep 3;
	`$adb -s $DEVICE_SERIAL shell dmesg > ~/rebootnew.log` &
	echo "adb shelled"
	sleep 3;
	`$adb -s $DEVICE_SERIAL shell dmesg > ~/rebootnew2.log` &

	# make sure kmsg was not empty
	# grep for something in the kernel message so thatthe condition below is true
	# and system can be rebooted.

	#k=`grep "Linux version" ~/rebootnew.log`
	#if [ ! -z "$k" ]; then
	#echo $k
	sleep 5; echo "::::::::::::::::  REBOOTING $j ::::::::::::::::"
	$adb -s $DEVICE_SERIAL reboot
	i=`expr $i - 1`
	j=`expr $j + 1`
	#else
	#cp ~/rebootnew.log ~/reboot_fail.log
	#$adb -s $DEVICE_SERIAL root
	#$adb -s $DEVICE_SERIAL bugreport>~/reboot_bugreport.txt
	#break;
	#fi
done

