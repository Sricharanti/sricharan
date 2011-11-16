#!/bin/bash

echo -e "Setting Multi Measurement Mode for Digital Compass:\n"
echo $DIGITAL_COMPASS_MULTI_MODE > $DIGITAL_COMPASS_OM
echo "1">$DIGITAL_COMPASS_ENABLE

#TMPFILE=`mktemp /var/tmpXXXXXX`
$SENSOR_DIR_BINARIES/evtest $DIGITAL_COMPASS_INPUTDEV >$TMPFILE
$SENSOR_DIR_HELPER/varvar.sh<$TMPFILE
RV=$?
rm $TMPFILE
echo "0">$DIGITAL_COMPASS_ENABLE

if [ "$RV" -eq "0" ]
then
	echo -e "PASS: Multi Measurement Test\n"
else
	echo -e "FAIL: Multi Measurement Test\n"
fi

exit $RV
