#!/bin/sh

# TestSuite General Variables
export SENSOR_POSTFIX=`date "+%Y%m%d-%H%M%S"`
export SENSOR_ROOT=`pwd`

export SENSOR_DIR_BINARIES=${SENSOR_ROOT}/../bin
export SENSOR_DIR_HELPER=${SENSOR_ROOT}/helper
export SENSOR_DIR_TMP=${SENSOR_ROOT}/tmp
export SENSOR_DIR_TEST=${SENSOR_ROOT}/test
export SENSOR_DIR_SCENARIOS="${SENSOR_ROOT}/scenarios"

export SENSOR_FILE_OUTPUT=${SENSOR_ROOT}/output.$SENSOR_POSTFIX
export SENSOR_FILE_LOG=${SENSOR_ROOT}/log.$SENSOR_POSTFIX
export SENSOR_FILE_TMP=${SENSOR_DIR_TMP}/tmp.$SENSOR_POSTFIX
export SENSOR_FILE_CMD=cmd.$SENSOR_POSTFIX

export SENSOR_DURATION=""
export SENSOR_PRETTY_PRT=""
export SENSOR_VERBOSE=""
export SENSOR_SCENARIO_NAMES=""
export SENSOR_STRESS=""

export PATH="${PATH}:${SENSOR_ROOT}:${SENSOR_DIR_BINARIES}:${SENSOR_DIR_HELPER}"

# Utils General Variables
export UTILS_DIR=$SENSOR_ROOT/../../utils/
export UTILS_DIR_BIN=$UTILS_DIR/bin
export UTILS_DIR_HANDLERS=$UTILS_DIR/handlers
export UTILS_DIR_SCRIPTS=$UTILS_DIR/scripts

export PATH="$PATH:$UTILS_DIR_BIN:$UTILS_DIR_HANDLERS:$UTILS_DIR_SCRIPTS"

. $UTILS_DIR/configuration/general.configuration
if [ `cat $SYSFS_BOARD_REV | grep -c "Tablet"` -ge 1 ]; then
	#specific to tsl2771 sensor
	export PROXIMITY_HW="tsl2771"
	export PROXIMITY_INPUTDEV="tsl2771_prox"
	export PROXIMITY_SYSFS_PATH="/sys/bus/i2c/drivers/tsl2771/4-0039"
	export PROXIMITY_ENABLE="$PROXIMITY_SYSFS_PATH/prox_enable"
elif [ `cat $SYSFS_BOARD_REV | grep -wc "Blaze/SDP"` -ge 1  ]; then
	#specific to sfh7741 sensor
	export PROXIMITY_HW="sfh7741"
	export PROXIMITY_INPUTDEV="sfh7741"
elif [ `cat /proc/cpuinfo| grep -ic OMAP5` -ne 0 ];then
	#specific to tsl2771 sensor
	export PROXIMITY_HW="tsl2771"
	export PROXIMITY_INPUTDEV="tsl2771_prox"
	export PROXIMITY_SYSFS_PATH="/sys/bus/i2c/drivers/tsl2771/2-0039"
else
	echo "Warning: Unrecognized hardware platform"
	exit 1
fi

# General variables
export DMESG_FILE=/var/log/dmesg

$UTILS_DIR_SCRIPTS/mknodins.sh

# Sensor devfs node
TEMP_EVENT=`ls /sys/class/input/ | grep event`
set $TEMP_EVENT

for i in $TEMP_EVENT
do
	cat /sys/class/input/$i/device/name | grep $PROXIMITY_INPUTDEV
	IS_THIS_OUR_DRIVER=`echo $?`
	if [ "$IS_THIS_OUR_DRIVER" -eq "0" ]
	then
		export DEVFS_SENSOR=/dev/input/$i
		echo "Proximity node is " $DEVFS_SENSOR
	fi
done

if [ ! -e "$DEVFS_SENSOR" ]
then
	echo "FATAL: Proximity node cannot be found -> $DEVFS_SENSOR"
fi

# End of file
