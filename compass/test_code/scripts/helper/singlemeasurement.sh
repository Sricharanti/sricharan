#!/bin/bash

echo -e "Setting Single Measurement Mode for Digital Compass:\n"
echo $DIGITAL_COMPASS_SINGLE_MODE > $DIGITAL_COMPASS_OM

echo "1">$DIGITAL_COMPASS_ENABLE

$SENSOR_DIR_BINARIES/evtest 1 $DIGITAL_COMPASS_INPUTDEV |$SENSOR_DIR_HELPER/varvar.sh

RV=$?
echo -e "Setting Multi Measurement Mode for Digital Compass:\n"
echo $DIGITAL_COMPASS_MULTI_MODE > $DIGITAL_COMPASS_OM
echo "0">$DIGITAL_COMPASS_ENABLE

if [ $RV -eq 0 ]
then
	echo -e "PASS: Multi Measurement Test\n"
else
	echo -e "FAIL: Multi Measurement Test\n"
fi
exit $RV