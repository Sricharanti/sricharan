#!/bin/sh

DURATION=$1
ATTACK=$2
ON=$3
OFF=$4

NOWTIME=`date "+%s"`
ENDTIME=`expr "$NOWTIME" + "$DURATION"`
sleep $ATTACK
while [ "$NOWTIME" -lt "$ENDTIME" ]; do
	handlerSysFs.sh "set" $VIBRATOR_SYSFS_PATH/enable ${ON}000
	sleep `expr $ON + $OFF - $ATTACK`
	ATTACK=0
    NOWTIME=`date "+%s"`
done





