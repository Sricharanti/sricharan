#!/bin/sh

#
#  CPU hotplug handler
#
#  Copyright (c) 2011 Texas Instruments
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
time=$2
command=$3

error_val=0

# =============================================================================
# Functions
# =============================================================================

cpuHotPlug() {

	command_line=$@
	error_val=0
	iteration=1

	if [ -n "$command_line" ]; then
		eval $command_line &
		command_pid=`echo $!`
	fi

	while [ 1 ]; do
		echo "[ handlerCpuHotPlug ] ITERATION: $iteration"
		rem=$(( $iteration % 2 ))
		if [ $rem -eq 1 ]
		then
			echo "[ handlerCpuHotPlug ] CPU1 ON | Frequency $time seconds"
			handlerSysFs.sh "set" $SYSFS_CPU1_ONLINE "1"
			handlerSysFs.sh "compare" $SYSFS_CPU1_ONLINE "1"
			if [ $? -ne 0 ]; then
				echo "[ handlerCpuHotPlug ] FATAL: Not able to set CPU1 ON"
				handlerError.sh "log" "1" "halt" "handlerCpuHotPlug.sh"
				exit 1
			fi
		else
			echo "[ handlerCpuHotPlug ] CPU1 OFF | Frequency $time seconds"
			handlerSysFs.sh "set" $SYSFS_CPU1_ONLINE "0"
			handlerSysFs.sh "compare" $SYSFS_CPU1_ONLINE "0"
			if [ $? -ne 0 ]; then
				echo "[ handlerCpuHotPlug ] FATAL: Not able to set CPU1 OFF"
				handlerError.sh "log" "1" "halt" "handlerCpuHotPlug.sh"
				exit 1
			fi
		fi
		if [ -n "$command_line" ]; then
			test -d /proc/$command_pid
			if [ $? -ne 0 ]; then
				# get exit code of background process
				wait $command_pid
				if [ $? -ne 0 ]; then
					echo "[ handlerCpuHotPlug ] FATAL: failure detected in"\
						" background process"
					echo "[ handlerCpuHotPlug ] FATAL: <$command_line>"\
						" command failed"
					handlerError.sh "log" "1" "halt" "handlerCpuHotPlug.sh"
					exit 1
				fi
				break
			fi
		fi
		sleep $time
		iteration=`expr $iteration + 1`
	done
}


# =============================================================================
# Main
# =============================================================================

handlerError.sh "test"
if [ $? -eq 1 ]; then
	exit 1
fi

# Verify required sysfs entries
if [ ! -f $SYSFS_CPU0_ONLINE ]; then
	echo "[ handlerCpuHotPlug ] FATAL: $SYSFS_CPU0_ONLINE cannot be found!"
	handlerError.sh "log" "1" "halt" "handlerCpuHotPlug.sh"
	exit 1
fi

if [ ! -f $SYSFS_CPU1_ONLINE ]; then
	echo "[ handlerCpuHotPlug ] FATAL: $SYSFS_CPU1_ONLINE cannot be found!"
	handlerError.sh "log" "1" "halt" "handlerCpuHotPlug.sh"
	exit 1
fi

# Verify dual core support
handlerSysFs.sh "set" $SYSFS_CPU1_ONLINE "1"
handlerSysFs.sh "compare" $SYSFS_CPU_ONLINE "0-1"
if [ $? -ne 0 ]; then
	echo "[ handlerCpuHotPlug ] FATAL: No dual core support"
	handleError.sh "log" "1" "halt" "handlerCpuHotPlug.sh"
	exit 1
fi

if [ "$operation" = "run" ]; then

	cpuHotPlug $command

fi

exit $error_val

# End of file
