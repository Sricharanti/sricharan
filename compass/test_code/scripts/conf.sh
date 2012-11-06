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

. $UTILS_DIR/configuration/general.configuration

export PATH="$PATH:$UTILS_DIR_BIN:$UTILS_DIR_HANDLERS:$UTILS_DIR_SCRIPTS"

# General variables
export DMESG_FILE=/var/log/dmesg
if [ `cat /proc/cpuinfo| grep -ic OMAP4` -ne 0 ];then
export DIGITAL_COMPASS_SYSFS=/sys/devices/platform/omap/omap_i2c.4/i2c-4/4-001e
elif [ `cat /proc/cpuinfo| grep -ic OMAP5` -ne 0 ];then
export DIGITAL_COMPASS_SYSFS=/sys/devices/platform/omap_i2c.2/i2c-2/2-000c
else
echo "Unknown device. Can not find sysfs path."
fi
export DIGITAL_COMPASS_OM=$DIGITAL_COMPASS_SYSFS/mode
export DIGITAL_COMPASS_ENABLE=$DIGITAL_COMPASS_SYSFS/enable

export DIGITAL_COMPASS_ALL_AXIS=$DIGITAL_COMPASS_SYSFS/magn_*_raw
export DIGITAL_COMPASS_SINGLE_MODE=1
export DIGITAL_COMPASS_MULTI_MODE=0


$UTILS_DIR_SCRIPTS/mknodins.sh

# Sensor devfs node
TEMP_EVENT=`ls /sys/class/input/ | grep event`
set $TEMP_EVENT

for i in $TEMP_EVENT
do
	cat /sys/class/input/$i/device/name | grep "hmc5843"
	IS_THIS_OUR_DRIVER=`echo $?`
	if [ "$IS_THIS_OUR_DRIVER" -eq "0" ]
	then
		export DIGITAL_COMPASS_INPUTDEV=/dev/input/$i
		echo "Compass node is " $DIGITAL_COMPASS_INPUTDEV
	fi
done

if [ ! -e "$DIGITAL_COMPASS_INPUTDEV" ]
then
	echo "FATAL: Compass node cannot be found -> $DIGITAL_COMPASS_INPUTDEV"
fi

# End of file
