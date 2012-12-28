#!/bin/sh -x

# TestSuite General Variables
export LED_POSTFIX=`date "+%Y%m%d-%H%M%S"`
export LED_ROOT=`pwd`

export LED_DIR_BINARIES=${LED_ROOT}/../bin
export LED_DIR_HELPER=${LED_ROOT}/helper
export LED_DIR_TMP=${LED_ROOT}/tmp
export LED_DIR_TEST=${LED_ROOT}/test
export LED_DIR_SCENARIOS="${LED_ROOT}/scenarios"

export LED_FILE_OUTPUT=${LED_ROOT}/output.$LED_POSTFIX
export LED_FILE_LOG=${LED_ROOT}/log.$LED_POSTFIX
export LED_FILE_TMP=${LED_DIR_TMP}/tmp.$LED_POSTFIX
export LED_FILE_CMD=cmd.$LED_POSTFIX

export LED_DURATION=""
export LED_PRETTY_PRT=""
export LED_VERBOSE=""
export LED_SCENARIO_NAMES=""
export LED_STRESS=""

export LED_SYSFS_PATH="/sys/class/leds"

export LED_KEYPAD_LED_PATH="keyboard-backlight"
export LED_BATTERY_LED_PATH="battery-led"
export LED_RED_LED_PATH="red"
export LED_GREEN_LED_PATH="green"
export LED_BLUE_LED_PATH="blue"

export PATH="${PATH}:${LED_ROOT}:${LED_DIR_BINARIES}:${LED_DIR_HELPER}"

# Utils General Variables
export UTILS_DIR=$LED_ROOT/../../utils/
export UTILS_DIR_BIN=$UTILS_DIR/bin
export UTILS_DIR_HANDLERS=$UTILS_DIR/handlers
export UTILS_DIR_SCRIPTS=$UTILS_DIR/scripts

. $UTILS_DIR/configuration/general.configuration

export PATH="$PATH:$UTILS_DIR_BIN:$UTILS_DIR_HANDLERS:$UTILS_DIR_SCRIPTS"

if [ `cat $SYSFS_BOARD_REV | grep -c "Tablet"` -ne "0" ]; then
	export HW_PLATFORM=tablet
	export LED_DISPLAY_LED_PATH="/sys/class/leds/lcd-backlight"
elif [ `cat $SYSFS_BOARD_REV | grep -wc "Blaze/SDP"` -ne 0  ]; then
	export HW_PLATFORM=blaze
	export LED_DISPLAY_LED_PATH="/sys/class/leds/lcd-backlight"
elif [ `cat /proc/cpuinfo| grep -ic OMAP5` -ne 0 ];then
	export HW_PLATFORM=omap5sevm
	export LED_DISPLAY_LED_PATH="/sys/devices/omapdss/display0/backlight/lg4591"
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
	if [ `cat /proc/cpuinfo| grep -ic OMAP5` -ne 0 ];then
		cat /sys/class/input/$i/device/name | grep "smsc_keypad"
	else
		cat /sys/class/input/$i/device/name | grep "keypad"
	fi

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
