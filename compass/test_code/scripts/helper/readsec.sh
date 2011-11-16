#!/bin/sh

DURATION=60

echo $DIGITAL_COMPASS_MULTI_MODE > $DIGITAL_COMPASS_OM
echo -n "1">$DIGITAL_COMPASS_ENABLE

#TMPFILE=`mktemp /var/tmpXXXXXX`
NOWTIME=`date "+%s"`
ENDTIME=`expr "$NOWTIME" + "$DURATION"`
ERROR_FLAG=0
while [ "$NOWTIME" -lt "$ENDTIME" ]; do
	$SENSOR_DIR_BINARIES/evtest $DIGITAL_COMPASS_INPUTDEV >$TMPFILE
	ERROR_FLAG=$?
	if [ "$?" -ne "0" ]; then
		break
	fi
    NOWTIME=`date "+%s"`
done
rm $TMPFILE

if [ "$ERROR_FLAG" -eq "0" ]
then
	echo -e "PASS: $DURATION second read w/ varying dvfs settings\n"
else
	echo -e "FAIL: $DURATION second read w/ varying dvfs settings\n"
fi

exit $ERROR_FLAG

