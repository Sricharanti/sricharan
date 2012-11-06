#!/bin/sh -x

# TestSuite General Variables
export AMBIENT_LIGHT_POSTFIX=`date "+%Y%m%d-%H%M%S"`
export AMBIENT_LIGHT_ROOT=`pwd`

export AMBIENT_LIGHT_DIR_BINARIES=${AMBIENT_LIGHT_ROOT}/../bin
export AMBIENT_LIGHT_DIR_HELPER=${AMBIENT_LIGHT_ROOT}/helper
export AMBIENT_LIGHT_DIR_TMP=${AMBIENT_LIGHT_ROOT}/tmp
export AMBIENT_LIGHT_DIR_TEST=${AMBIENT_LIGHT_ROOT}/test
export AMBIENT_LIGHT_DIR_SCENARIOS="${AMBIENT_LIGHT_ROOT}/scenarios"

export AMBIENT_LIGHT_FILE_OUTPUT=${AMBIENT_LIGHT_ROOT}/output.$AMBIENT_LIGHT_POSTFIX
export AMBIENT_LIGHT_FILE_LOG=${AMBIENT_LIGHT_ROOT}/log.$AMBIENT_LIGHT_POSTFIX
export AMBIENT_LIGHT_FILE_TMP=${AMBIENT_LIGHT_DIR_TMP}/tmp.$AMBIENT_LIGHT_POSTFIX
export AMBIENT_LIGHT_FILE_CMD=cmd.$AMBIENT_LIGHT_POSTFIX

export AMBIENT_LIGHT_DURATION=""
export AMBIENT_LIGHT_PRETTY_PRT=""
export AMBIENT_LIGHT_VERBOSE=""
export AMBIENT_LIGHT_SCENARIO_NAMES=""
export AMBIENT_LIGHT_STRESS=""

# Utils General Variables
export UTILS_DIR=$AMBIENT_LIGHT_ROOT/../../utils/
export UTILS_DIR_BIN=$UTILS_DIR/bin
export UTILS_DIR_HANDLERS=$UTILS_DIR/handlers
export UTILS_DIR_SCRIPTS=$UTILS_DIR/scripts

export PATH="${PATH}:${AMBIENT_LIGHT_ROOT}:${AMBIENT_LIGHT_DIR_BINARIES}:${AMBIENT_LIGHT_DIR_HELPER}"
export PATH="$PATH:$UTILS_DIR_BIN:$UTILS_DIR_HANDLERS:$UTILS_DIR_SCRIPTS"

. $UTILS_DIR/configuration/general.configuration
if [ `cat $SYSFS_BOARD_REV | grep -c "Tablet"` -ge 1 ]; then
	#specific to tsl2771 sensor
	export AMBIENT_LIGHT_SYSFS_PATH="/sys/bus/i2c/drivers/tsl2771/4-0039"
	export AMBIENT_LIGHT_POWERON_VAL=1
	export AMBIENT_LIGHT_POWEROFF_VAL=0
	export AMBIENT_LIGHT_ENABLE_POWER="$AMBIENT_LIGHT_SYSFS_PATH/als_enable"
elif [ `cat $SYSFS_BOARD_REV | grep -wc "Blaze/SDP"` -ge 1  ]; then
	# Specific to bh1780 sensor
	export AMBIENT_LIGHT_MODE_MEAS400=2
	export AMBIENT_LIGHT_MODE_MOTDET=4
	export AMBIENT_LIGHT_RANGE_2G=2000
	export AMBIENT_LIGHT_RANGE_8G=8000
	export AMBIENT_LIGHT_SYSFS_PATH="/sys/bus/i2c/drivers/bh1780/3-0029"
	export AMBIENT_LIGHT_POWERON_VAL=3
	export AMBIENT_LIGHT_POWEROFF_VAL=0
	export AMBIENT_LIGHT_ENABLE_POWER="$AMBIENT_LIGHT_SYSFS_PATH/power_state"
elif [ `cat /proc/cpuinfo| grep -ic OMAP5` -ne 0 ];then
	#specific to tsl2771 sensor
	export AMBIENT_LIGHT_SYSFS_PATH="/sys/bus/i2c/drivers/tsl2771/2-0039"
	export AMBIENT_LIGHT_POWERON_VAL=1
	export AMBIENT_LIGHT_POWEROFF_VAL=0
	export AMBIENT_LIGHT_ENABLE_POWER="$AMBIENT_LIGHT_SYSFS_PATH/als_enable"
else
	echo "Warning: Unrecognized hardware platform"
	exit 1
fi

# General variables
export DMESG_FILE=/var/log/dmesg

# Keypad devfs node
TEMP_EVENT=`ls /sys/class/input/ | grep event`
set $TEMP_EVENT

for i in $TEMP_EVENT
do
	cat /sys/class/input/$i/device/name | grep "keypad"
	IS_THIS_OUR_DRIVER=`echo $?`
	if [ "$IS_THIS_OUR_DRIVER" -eq "0" ]
	then
		export DEVFS_KEYPAD=/dev/input/$i
		echo "Keypad node is " $DEVFS_KEYPAD
	fi
done

if [ ! -e "$DEVFS_KEYPAD" ]
then
	echo "Warning: Keypad node cannot be found -> $DEVFS_KEYPAD"
fi

# End of file
