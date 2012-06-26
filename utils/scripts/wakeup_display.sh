#!/bin/sh

# Helper script to turn on the display if it off
#
# Author: Leed Aguilar <leed.aguilar@ti.com>
#

# Verify we have all the required sysfs entries
if [ ! -f $SYSFS_OMAPDSS_OV0_EN ]; then
	echo -e "[wakeup display] OMAPDSS Overlay0 sysfs entry is not available"
	echo -e "[wakeup display] The script can not be executed"
	exit 1
fi

# Verify the status of the framebuffer
handlerSysFs.sh verify $SYSFS_OMAPDSS_OV0_EN 0
if [ $? -eq 0 ]; then
	handlerInputSubsystem.sh "keypad" "KeyCodePowerKey" 1 1 1
fi

exit 0
