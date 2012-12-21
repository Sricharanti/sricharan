#!/bin/bash

echo -n $GYRO_POWERON_VAL>$GYRO_ENABLE_POWER
echo -n "20">$GYRO_DELAY

#TMPFILE=`mktemp /var/tmpXXXXXX`
$GYRO_DIR_BINARIES/evtest $DEVFS_GYRO >$TMPFILE
$GYRO_DIR_HELPER/vargyr.sh<$TMPFILE
RV=$?
rm $TMPFILE

if [ "$RV" -eq "0" ]
then
	echo -e "PASS: raw event Test\n"
else
	echo -e "FAIL: raw event Test\n"
fi

exit $RV
