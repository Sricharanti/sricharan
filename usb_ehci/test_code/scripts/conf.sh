#!/bin/sh

# TestSuite General Variables
export USBHOST_POSTFIX=`date "+%Y%m%d-%H%M%S"`
export USBHOST_ROOT=`pwd`

export USBHOST_DIR_BINARIES=${USBHOST_ROOT}/../bin
export USBHOST_DIR_HELPER=${USBHOST_ROOT}/helper
export USBHOST_DIR_TMP=${USBHOST_ROOT}/tmp
export USBHOST_DIR_TEST=${USBHOST_ROOT}/test
export USBHOST_DIR_SCENARIOS="${USBHOST_ROOT}/scenarios"
export USBHOST_BIN=${USBHOST_ROOT}/../bin

export USBHOST_FILE_OUTPUT=${USBHOST_ROOT}/output.$USBHOST_POSTFIX
export USBHOST_FILE_LOG=${USBHOST_ROOT}/log.$USBHOST_POSTFIX
export USBHOST_FILE_TMP=${USBHOST_DIR_TMP}/tmp.$USBHOST_POSTFIX
export USBHOST_FILE_CMD=cmd.$USBHOST_POSTFIX

export DELAY1=3
export USBHOST_DURATION=""
export USBHOST_PRETTY_PRT=""
export USBHOST_VERBOSE=""
export USBHOST_SCENARIO_NAMES=""
export USBHOST_STRESS=""

export PATH="${USBHOST_ROOT}:${USBHOST_DIR_HELPER}:${PATH}"

# Utils General Variables
export UTILS_DIR_BIN=${USBHOST_ROOT}/../../utils/bin
export UTILS_DIR_HANDLERS=${USBHOST_ROOT}/../../utils/handlers
export UTILSMODULES=${USBHOST_ROOT}/../modules
export UTILS=${USBHOST_ROOT}/../utils
export SYSFS_EHCI_OMAP=/sys/devices/platform/ehci-omap.0/
export SYSFS_OHCI_OMAP=/sys/devices/platform/ohci-omap.0/
export USBHOST_ENUMERATION=/sys/devices/platform/musb_hdrc/mode

# USB Host Specific Variables
export USBHOST_TEMP_VARIABLE=1
export USBHOST_MODULES_STORAGE=${TESTMODULES}
export USBHOST_RESULTS_STORAGE=${TMPBASE}
export USBHOST_DEVFS_ENTRY=/dev/sda
export USBHOST_DEVFS_PARTITION=/dev/sda1
export USBHOST_MOUNTPOINT_PATH=/mnt/mass_storage
export USBHOST_HID_NODE=/dev/event2

# USB Keypad devfs node
export USB_KEYBOARD_ITERATIONS=50
TEMP_EVENT=`ls /sys/class/input/ | grep event`
set $TEMP_EVENT

for i in $TEMP_EVENT
do
	cat /sys/class/input/$i/device/name | grep "Keyboard"
	IS_THIS_OUR_DRIVER=`echo $?`
	if [ "$IS_THIS_OUR_DRIVER" -eq "0" ]
	then
		export DEVFS_USB_KEYBOARD=/dev/input/$i
		echo "USB keyboard node is " $DEVFS_USB_KEYBOARD
	fi
done

if [ ! -e "$DEVFS_USB_KEYBOARD" ]
then
	echo "Warning: USB keyboard node cannot be found -> $DEVFS_USB_KEYBOARD"
fi

# End of file
