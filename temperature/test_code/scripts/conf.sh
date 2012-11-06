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
export DEVFS_TEMP=/sys/class/hwmon/hwmon0/device/temp1_input
elif [ `cat /proc/cpuinfo| grep -ic OMAP5` -ne 0 ];then
export DEVFS_TEMP=/sys/bus/i2c/drivers/bmp085/2-0077/temp0_input
else
echo "Unknown device, please provide configuration."
fi

# End of file
