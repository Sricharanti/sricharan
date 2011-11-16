#!/bin/sh

DURATION=30

echo -n "$AMBIENT_LIGHT_POWERON_VAL">$AMBIENT_LIGHT_ENABLE_POWER 

NOWTIME=`date "+%s"`
ENDTIME=`expr "$NOWTIME" + "$DURATION"`
RV=0
while [ "$NOWTIME" -lt "$ENDTIME" ]; do
	cat $AMBIENT_LIGHT_SYSFS_PATH/lux >/dev/null
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
	

