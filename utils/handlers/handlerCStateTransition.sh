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

operation=$1
error_val=0
cpu0_state_dir=/sys/devices/system/cpu/cpu0/cpuidle
cpu1_state_dir=/sys/devices/system/cpu/cpu1/cpuidle

# =============================================================================
# Functions
# =============================================================================
# Prints a message with a specific format
# @ Function: showInfo
# @ Parameters: <message to display>
# @ Return: None
showInfo() {
        message="$@"
        echo "[ handlerCStateTransition ] $message"
}

# =============================================================================
# Main
# =============================================================================

handlerError.sh "test"
if [ $? -eq 1 ]; then
        exit 1
fi

handlerDebugFileSystem.sh "mount"

if [ "$operation" = "log" ]; then

        cpu_state=$2
        log_name=$3
        cpu0_state_place=0
	cpu1_state_place=0

        if [ "$cpu_state" = "state0" ]; then
                cpu0_state_place=$cpu0_state_dir/state0/usage
		cpu1_state_place=$cpu1_state_dir/state0/usage
        elif [ "$cpu_state" = "state1" ]; then
                cpu0_state_place=$cpu0_state_dir/state1/usage
		cpu1_state_place=$cpu1_state_dir/state1/usage
        elif [ "$cpu_state" = "state2" ]; then
                cpu0_state_place=$cpu0_state_dir/state2/usage
		cpu1_state_place=$cpu1_state_dir/state2/usage
        elif [ "$cpu_state" = "state3" ]; then
                cpu0_state_place=$cpu0_state_dir/state3/usage
		cpu1_state_place=$cpu1_state_dir/state3/usage
        fi

        cpu0_state_value=`cat $cpu0_state_place`
	cpu1_state_value=`cat $cpu1_state_place`
        showInfo "CPU state requested: $cpu_state"
        echo $cpu0_state_value > $UTILS_DIR_TMP/pts.cpu0.$cpu_state.$log_name
	echo $cpu1_state_value > $UTILS_DIR_TMP/pts.cpu1.$cpu_state.$log_name

elif [ "$operation" = "compare" ]; then

        cpu_state=$2
        log_name_before=$3
	log_name_after=$4
        val_cpu0_before=`cat $UTILS_DIR_TMP/pts.cpu0.$cpu_state.$log_name_before`
	val_cpu1_before=`cat $UTILS_DIR_TMP/pts.cpu1.$cpu_state.$log_name_before`
	val_cpu0_after=`cat $UTILS_DIR_TMP/pts.cpu0.$cpu_state.$log_name_after`
        val_cpu1_after=`cat $UTILS_DIR_TMP/pts.cpu1.$cpu_state.$log_name_after`

        showInfo "CPU0 state: Initial Value -> $cpu_state: $val_cpu0_before"
	showInfo "CPU0 state: Final Value -> $cpu_state: $val_cpu0_after"
	showInfo "CPU1 state: Initial Value -> $cpu_state: $val_cpu1_before"
	showInfo "CPU1 state: Final Value -> $cpu_state: $val_cpu1_after"

        # Verify the power domain counter increases
        showInfo "Verifying cpu0 && cpu1 : $cpu_state  value were hint ..."
        #sleep 10

        if  [ $val_cpu0_before == $val_cpu0 after ] || [ $val_cpu1_before == $val_cpu1_after ] ; then
                showInfo "ERROR: $cpu_state wasn't hint"
                showInfo "TEST FAILED"
                error_val=1
        elif [ $val_cpu0_after != $val_cpu0_before ] || [ $val_cpu1_before != $val_cpu1_after ] ; then
                showInfo "SUCCESS: $cpu_state was hint"
                showInfo "TEST PASSED"
                error_val=0
        else
                showInfo "FATAL: Please review cpu states counters"
                error_val=1
        fi
fi

#handlerDebugFileSystem.sh "umount"

exit $error_val

# End of file
