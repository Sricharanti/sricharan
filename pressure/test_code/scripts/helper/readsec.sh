#!/bin/sh

DURATION=30

echo -n "1">$DEVFS_BMP085_DIR/enable

NOWTIME=`date "+%s"`
ENDTIME=`expr "$NOWTIME" + "$DURATION"`
RV=0
while [ "$NOWTIME" -lt "$ENDTIME" ]; do
	cat $DEVFS_BMP085_PRESS >/dev/null
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
	

