#!/bin/sh

DURATION=30

if [ -n "$PROXIMITY_ENABLE" ]; then
	echo -n "2">$PROXIMITY_ENABLE
fi

NOWTIME=`date "+%s"`
ENDTIME=`expr "$NOWTIME" + "$DURATION"`
RV=0
while [ "$NOWTIME" -lt "$ENDTIME" ]; do
	$SENSOR_ROOT/../bin/evtest $DEVFS_SENSOR
	if [ "$?" -ne "0" ]; then
		RV=1
		break
	fi
    NOWTIME=`date "+%s"`
done

if [ "$RV" -eq "0" ]
then
	echo -e "PASS: $DURATION second read w/ varying dvfs settings\n"
else
	echo -e "FAIL: $DURATION second read w/ varying dvfs settings\n"
fi

exit $RV
	
