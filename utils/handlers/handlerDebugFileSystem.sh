#!/bin/sh

#  Copyright (c) 2011 Texas Instruments
#
#  Author: Abraham Arce <x0066660@ti.com>
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

# =============================================================================
# Variables
# =============================================================================

command=$1
debugfs_entry_value=$2
debugfs_entry_name=$3

# =============================================================================
# Functions
# =============================================================================

# None

# =============================================================================
# Main
# =============================================================================

handlerError.sh "test"
if [ $? -eq 1 ]; then
	exit 1
fi

if [ "$command" = "mount" ]; then

	# Verify/Create debugfs mount point
	test -d $PM_DEBUGFS_DIRECTORY || mkdir -p $PM_DEBUGFS_DIRECTORY
	mount | grep debugfs | grep "$PM_DEBUGFS_DIRECTORY on $PM_DEBUGFS_DIRECTORY"
	if [ $? -ne 0 ]; then
		# mount debugfs
		mount -t debugfs debugfs $PM_DEBUGFS_DIRECTORY
		if [ $? -ne 0 ]; then
			echo "[handlerDebugFS] Error: debugfs can not be mounted"
			handlerError.sh "log" "1" "halt" "handlerDebugFileSystem.sh"
			exit 1
		else
			echo "[handlerDebugFS] debugfs was successfully mounted"
		fi
	fi

elif [ "$command" = "set" ]; then

	handlerDebugFileSystem.sh "mount"
	test -f $debugfs_entry_name
	if [ $? -ne 0 ]; then
		echo "[handlerDebugFS] Error: < $debugfs_entry_name > doesn't exist"
		handlerError.sh "log" "1" "halt" "handlerDebugFileSystem.sh"
		exit 1
	fi

	handlerSysFs.sh "set" $debugfs_entry_name $debugfs_entry_value
	handlerSysFs.sh "verify" $debugfs_entry_name $debugfs_entry_value
	if [ $? -ne 0 ]; then
		echo "[handlerDebugFS] Error: Not able to write into $debugfs_entry_name"
		handlerError.sh "log" "1" "halt" "handlerDebugFileSystem.sh"
		exit 1
	fi

elif [ "$command" = "umount" ]; then

	umount $PM_DEBUGFS_DIRECTORY
	if [ $? -ne 0 ]; then
		echo "[handlerDebugFS] Error: Unable to umount debugfs"
		exit 1
	fi
fi

# End of file
