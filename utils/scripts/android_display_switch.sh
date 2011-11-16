#!/bin/sh

#
#  android_display_switch.sh
#
#  Copyright (c) 2011 Texas Instruments
#
#  Author: Leed Aguilar <leed.aguilar@ti.com>
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License as
#  published by the Free Software Foundation; either version 2 of the
#  License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
#  USA
#

# This scripts turn Android screen ON and OFF. It verifies for specific
# system conditions to make this process more reliable

# =============================================================================
# Local Variables
# =============================================================================

status=$1

# =============================================================================
# Functions
# =============================================================================

# Display the script usage
# @ Function: usage
# @ parameters: None
# @ Return: Error flag value
usage() {
	echo ""
	echo "---------------------------------------------"
	echo "usage: android_display_switch.sh {ON|OFF}"
	echo "---------------------------------------------"
	echo ""
	exit 1
}

# Prints a message with a specific format
# @ Function: showInfo
# @ Parameters: <message to display>
# @ Return: None
showInfo() {
	message=$1
	echo "[ Android Display Switch ] $message"
}


# =============================================================================
# MAIN
# =============================================================================

# Verify script usage
if [ $# -ne 1 ]; then
	usage 1>&2
fi

# Verify we have all the required sysfs entried
if [ ! -f $SYSFS_OMAPDSS_OV0_EN ]; then
	showInfo "OMAPDSS Overlay0 sysfs entry is not available"
	showInfo "The script can not be executed without this entry"
	exit 1
fi

if [ "$status" = "ON" ]; then
	# verify status of the Framebuffer
	if [ `cat $SYSFS_OMAPDSS_OV0_EN` -eq 1 ]; then
		showInfo "Display is already ON"
		input keyevent $KeyMonkeyMenu
	else
		handlerInputSubsystem.sh "keypad" "KeyCodePowerKey" 1 1 1
		sleep 1
		input keyevent $KeyMonkeyMenu
	fi
elif [ "$status" = "OFF" ]; then
	# verify status of the Framebuffer
	if [ `cat $SYSFS_OMAPDSS_OV0_EN` -eq 0 ]; then
		showInfo "Display is already OFF"
	else
		# A wakelock must be previously registered or the system
		# will enter to suspend state
		handlerInputSubsystem.sh "keypad" "KeyCodePowerKey" 1 1 1
	fi
else
	usage 1>&2
fi

exit 0

# End of file
