#!/bin/sh

# This script performs four different tasks: set, get, compare and verify
# These different commands allow the user to interact with any syfs entry
# The error validation for compare/verify functions helps to validate the read
# and write operations of this script.

#  Copyright (c) 2010 Texas Instruments
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

# =============================================================================
# Variables
# =============================================================================

command=$1
sysfs_entry_name=$2
sysfs_entry_value=$3

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

# Validate sysfs entry
test -f $sysfs_entry_name
if [ $? != 0 ]; then
	echo "[ handlerSysFs ] Error: < $sysfs_entry_name > does not exist"
	handlerError.sh "log" "1" "halt" "handlerSysFs.sh"
	exit 1
fi

# Set a value to a specific sysfs entry. Don't check for errors here
if [ "$command" = "set" ]; then

	echo -n "$sysfs_entry_name"  > $HSF_SYSFS_ENTRY_NAME
	echo -n "$sysfs_entry_value" > $sysfs_entry_name

# Obtain current value from a specific sysfs entry
elif [ "$command" = "get" ]; then

	cat $sysfs_entry_name

# The "compare" command differs from "verify" in that the first one registers
# a failure that can be propagated outside of this script using the handlerError
elif [ "$command" = "compare" ] || [ "$LOCAL_COMMAND" = "verify" ]; then

	sysfs_entry_current=`cat $sysfs_entry_name`
	echo "[ handlerSysFs ] Desired Value: $sysfs_entry_value" \
				"| Current Value: $sysfs_entry_current"

	if [ "$sysfs_entry_value" = "$sysfs_entry_current" ]; then
		echo "[ handlerSysFs ] PASS: comparison succeeded"
		exit 0
	else
		echo "[ handlerSysFs ] FAIL: comparison failed" 1>&2
		if [ "$command" = "compare" ]; then
			handlerError.sh "log" "1" "halt" "handlerSysFs.sh"
		fi
		exit 1
	fi

fi

# End of file
