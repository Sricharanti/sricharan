#!/bin/sh

DURATION=60

if [ -n "$PROXIMITY_ENABLE" ]; then 
	echo -n "1">$PROXIMITY_ENABLE
fi 

#TMPFILE=`mktemp /var/tmpXXXXXX`
NOWTIME=`date "+%s"`
ENDTIME=`expr "$NOWTIME" + "$DURATION"`
RV=0
while [ "$NOWTIME" -lt "$ENDTIME" ]; do
	$SENSOR_ROOT/../../compass/bin/evtest $DEVFS_SENSOR >$TMPFILE
	RV=$?
	if [ "$?" -ne "0" ]; then
		break
	fi
    NOWTIME=`date "+%s"`
done
rm $TMPFILE

if [ "$RV" -eq "0" ]
then
	echo -e "PASS: $DURATION second read w/ varying dvfs settings\n"
else
	echo -e "FAIL: $DURATION second read w/ varying dvfs settings\n"
fi

exit $RV
	
