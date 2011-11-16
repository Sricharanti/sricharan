#!/bin/sh

DURATION=60

meight=0

NOWTIME=`date "+%s"`
ENDTIME=`expr "$NOWTIME" + "$DURATION"`
RV=0
while [ "$NOWTIME" -lt "$ENDTIME" ]; do
	let "meight += 1"
	meight=`expr $meight % 8`
	#mfour=`expr $meight % 4`
	#one=`expr $meight % 2`
	#two=`expr $mfour / 2`
	#four=`expr $meight / 4`
	
	#echo $meight $four $two $one
	#if [ "0" -eq "$four" ]; then
	#	echo "0" > $LED_SYSFS_PATH/red/brightness
	#else
	#	echo "1" > $LED_SYSFS_PATH/red/brightness
	#fi
	#if [ "0" -eq "$two" ]; then
	#	echo "0" > $LED_SYSFS_PATH/green/brightness
	#else
	#	echo "1" > $LED_SYSFS_PATH/green/brightness
	#fi
	#if [ "0" -eq "$one" ]; then
	#	echo "0" > $LED_SYSFS_PATH/blue/brightness
	#else
	#	echo "1" > $LED_SYSFS_PATH/blue/brightness
	#fi
	#if [ "0" -eq "$one" ]; then
	#	echo "1" > $LED_SYSFS_PATH/omap4\:green\:debug2/brightness
	#	echo "0" > $LED_SYSFS_PATH/omap4\:green\:debug4/brightness
	#else
	#	echo "0" > $LED_SYSFS_PATH/omap4\:green\:debug2/brightness
	#	echo "1" > $LED_SYSFS_PATH/omap4\:green\:debug4/brightness
	#fi
	chrg=`expr $meight * 32
	echo "$chrg" > $LED_SYSFS_PATH/omap4\:green\:chrg/brightness
    NOWTIME=`date "+%s"`
done

exit $RV
	

