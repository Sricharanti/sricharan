#!/bin/bash

#
#  C-State transition Statistics handler
#
#  Copyright (c) 2010 Texas Instruments
#
#  Author: Mariia Nagul <x0171643@ti.com>
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

interface="$1"
operation="$2"
error_val=0
irq1_state_dir=/proc/interrupts

# =============================================================================
# Functions
# =============================================================================
# Prints a message with a specific format
# @ Function: showInfo
# @ Parameters: <message to display>
# @ Return: None
showInfo() {
	message="$@"
	echo "[ handlerIrqState ] $message"
}

# =============================================================================
# Main
# =============================================================================

handlerError.sh "test"
if [ $? -eq 1 ]; then
        exit 1
fi


if [ "$operation" = "log" ]; then

	log_name=$3

	int1=$(cat /proc/interrupts | grep $interface | awk '{print $2}')
	irq1_value=$(echo $int1 | sed "s/ [0-9 ]*//")
	showInfo " $interface state requested "
	echo $irq1_value > $UTILS_DIR_TMP/pts.${interface}_irq.$log_name

elif [ "$operation" = "compare" ]; then

	log_name_before=$3
	log_name_after=$4
	val_irq_before=`cat $UTILS_DIR_TMP/pts.${interface}_irq.$log_name_before`
	val_irq_after=`cat $UTILS_DIR_TMP/pts.${interface}_irq.$log_name_after`

	showInfo "$interface irq state: Initial Value -> $val_irq_before"
	showInfo "$interface irq state: Final Value -> $val_irq_after"

        # Verify the power domain counter increases
	showInfo "Verifying ${interface} irq value were hint ..."
	sleep 10

	if  [ $val_irq_before == $val_irq_after ] ;then
		showInfo "ERROR: ${interface} irq weren't hint"
		showInfo "TEST FAILED"
		error_val=1
	elif [ $val_${interface}_irq1_before != $val_${interface}_irq1_after ];then
		showInfo "SUCCESS: ${interface} irq were hint"
		showInfo "TEST PASSED"
		error_val=0
	else
		showInfo "FATAL: Please review ${interface}_irq states"
		error_val=1
	fi
fi

exit $error_val

# End of file
