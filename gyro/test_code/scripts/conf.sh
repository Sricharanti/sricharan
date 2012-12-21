#!/bin/sh -x

# TestSuite General Variables
export GYRO_POSTFIX=`date "+%Y%m%d-%H%M%S"`
export GYRO_ROOT=`pwd`

export GYRO_DIR_BINARIES=${GYRO_ROOT}/../bin
export GYRO_DIR_HELPER=${GYRO_ROOT}/helper
export GYRO_DIR_TMP=${GYRO_ROOT}/tmp
export GYRO_DIR_TEST=${GYRO_ROOT}/test
export GYRO_DIR_SCENARIOS="${GYRO_ROOT}/scenarios"

export GYRO_FILE_OUTPUT=${GYRO_ROOT}/output.$GYRO_POSTFIX
export GYRO_FILE_LOG=${GYRO_ROOT}/log.$GYRO_POSTFIX
export GYRO_FILE_TMP=${GYRO_DIR_TMP}/tmp.$GYRO_POSTFIX
export GYRO_FILE_CMD=cmd.$GYRO_POSTFIX

export GYRO_DURATION=""
export GYRO_PRETTY_PRT=""
export GYRO_VERBOSE=""
export GYRO_SCENARIO_NAMES=""
export GYRO_STRESS=""

export PATH="${PATH}:${GYRO_ROOT}:${GYRO_DIR_BINARIES}:${GYRO_DIR_HELPER}"

# Utils General Variables
export UTILS_DIR=$GYRO_ROOT/../../utils/
export UTILS_DIR_BIN=$UTILS_DIR/bin
export UTILS_DIR_HANDLERS=$UTILS_DIR/handlers
export UTILS_DIR_SCRIPTS=$UTILS_DIR/scripts

export PATH="$PATH:$UTILS_DIR_BIN:$UTILS_DIR_HANDLERS:$UTILS_DIR_SCRIPTS"

. $UTILS_DIR/configuration/general.configuration
if [ `cat $SYSFS_BOARD_REV | grep -c "Tablet"` -ge 1 ] ||
   [ `cat $SYSFS_BOARD_REV | grep -c "Panda"` -ge 1 ]; then
	# Specific to bma180 sensor
	export GYRO_SYSFS_PATH="/sys/bus/i2c/drivers/mpu3050_gyro/4-0068"
	export GYRO_HW="mpu3050"
	export GYRO_POWERON_VAL=1
	export GYRO_POWEROFF_VAL=0
	export GYRO_ENABLE_POWER="$GYRO_SYSFS_PATH/enable"
	export GYRO_DELAY="$GYRO_SYSFS_PATH/delay"
elif [ `cat /proc/cpuinfo| grep -ic OMAP5` -ne 0 ]; then
	export GYRO_SYSFS_PATH="/sys/bus/i2c/drivers/mpu6050/2-0068"
	export GYRO_HW="mpu6050-gyroscope"
	export GYRO_POWERON_VAL=1
	export GYRO_POWEROFF_VAL=0
	export GYRO_ENABLE_POWER="$GYRO_SYSFS_PATH/gyro_enable"
fi

# General variables
export DMESG_FILE=/var/log/dmesg

$UTILS_DIR_SCRIPTS/mknodins.sh

# Sensor devfs node
TEMP_EVENT=`ls /sys/class/input/ | grep event`
set $TEMP_EVENT

for i in $TEMP_EVENT
do
	cat /sys/class/input/$i/device/name | grep "$GYRO_HW"
	IS_THIS_OUR_DRIVER=`echo $?`
	if [ "$IS_THIS_OUR_DRIVER" -eq "0" ]
	then
		export DEVFS_GYRO=/dev/input/$i
		echo "Gyro node is " $DEVFS_GYRO
	fi
done

if [ ! -e "$DEVFS_GYRO" ]
then
	echo "FATAL: Gyro node cannot be found -> $DEVFS_GYRO"
	exit 1
fi

# End of file
