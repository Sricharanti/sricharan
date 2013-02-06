#!/bin/sh

#
#  CPU Frequency handler
#
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
#

# =============================================================================
# Variables
# =============================================================================

operation=$1
frequency_val=$2
cmd_to_execute=$3
error_val=0

# =============================================================================
# Functions
# =============================================================================

# This functions receives a OPP value and not a real frequency value
# Example: OPP5 or 5, OPP2 or 2
setOneFrequency() {

	opp_val=$1
	cmd_to_execute=$2
	frequency_val_number=`echo ${opp_val#OPP}`
	loop_number=0

	available_frequencies=`cat $SYSFS_CPU0_AVAILABLE_FREQUENCIES`

	for frequency in $available_frequencies
	do
		loop_number=`expr $loop_number + 1`
		echo $frequency	> $HCFSF_FREQUENCIES_LIST_AVAILABILITY.$loop_number
	done

	if [ $frequency_val_number -gt $loop_number ]; then
		showInfo "OPP$frequency_val_number does not exist"
		showInfo "Setting Frequency value to OPP$loop_number"
		frequency_val_number=$loop_number
	fi

	frequency_val=`cat $HCFSF_FREQUENCIES_LIST_AVAILABILITY.$frequency_val_number`
	if [ -z $frequency_val ]; then
		showInfo "FATAL: unknown frequency value"
		exit 1
	fi

	if [ -n "$cmd_to_execute" ]; then
		eval $cmd_to_execute &
		command_pid=`echo $!`
	fi

	handlerSysFs.sh set $SYSFS_CPU0_SET_SPEED $frequency_val
	handlerSysFs.sh verify $SYSFS_CPU0_CURRENT_FREQUENCY $frequency_val
	if [ $? -ne 0 ]; then
		showInfo "Error! Frequency $frequency_val could not be set"
	else
		showInfo "Frequency $frequency_val was correctly set"
	fi
	wait $command_pid
	if [ $? -ne 0 ]; then
		showInfo "FATAL: failure detected in background process"
		showInfo "FATAL: <$cmd_to_execute> command failed"
		handlerError.sh "log" "1" "halt" "handlerCpuFreqScalFrequencies.sh"
		exit 1
	fi
}

setAllFrequencies() {

	cmd_to_execute=$@
	error=0
	iteration=1
	# Clean log files
	echo > $HCFSF_FREQUENCIES_LIST_OK
	echo > $HCFSF_FREQUENCIES_LIST_ERROR

	available_frequencies=`cat $SYSFS_CPU0_AVAILABLE_FREQUENCIES`
	showInfo "INFO: Available frequencies are -> `echo $available_frequencies`"

	if [ -n "$cmd_to_execute" ]; then
		eval $cmd_to_execute &
		command_pid=`echo $!`
	fi

	while [ 1 ]; do
		echo "CPU Frquencies don't set correctly in cycle No $iteration:" >> $HCFSF_FREQUENCIES_LIST_ERROR
		echo "CPU Frquencies set correctly in cycle No $iteration:" >> $HCFSF_FREQUENCIES_LIST_OK
		for frequency in $available_frequencies; do
			showInfo "INFO: Setting Frequency to $frequency"
			handlerSysFs.sh set $SYSFS_CPU0_SET_SPEED $frequency
			handlerSysFs.sh verify $SYSFS_CPU0_CURRENT_FREQUENCY $frequency
			if [ $? -ne 0 ]; then
				showInfo "FAIL: Frequency $frequency cannot be set"
				echo $frequency >> $HCFSF_FREQUENCIES_LIST_ERROR
				error=1
			else
				showInfo "PASS: Frequency $frequency was set"
				echo $frequency >> $HCFSF_FREQUENCIES_LIST_OK
			fi
			# TODO: Add an option to set a delay between frequency changes
			sleep 1
		done

		if [ -n "$cmd_to_execute" ]; then
			test -d /proc/$command_pid
			if [ $? -ne 0 ]; then
				# get exit code of background process
				wait $command_pid
				if [ $? -ne 0 ]; then
					showInfo "FATAL: failure detected in background process"
					showInfo "FATAL: <$command_line> command failed"
					handlerError.sh "log" "1" "halt" "handlerCpuFreqScalFrequencies.sh"
					exit 1
				fi
				break
			fi
		else
			break
		fi
		iteration=`expr $iteration + 1`
	done

	showInfo "INFO: The following frequencies were set correctly:"
	cat $HCFSF_FREQUENCIES_LIST_OK
	if [ $error -eq 1 ]; then
		showInfo "INFO: The following frequencies were not set correctly"
		cat $HCFSF_FREQUENCIES_LIST_ERROR
		exit 1
	fi
}

showInfo() {
	echo "[ handlerCpuFreq ] $1"
}

# =============================================================================
# Main
# =============================================================================

handlerError.sh "test"
if [ $? -eq 1 ]; then
	exit 1
fi

# TODO: Add script usage

# Evaluate required sysfs entries

if [ ! -f $SYSFS_CPU0_AVAILABLE_FREQUENCIES ]; then
	showInfo "FATAL: $SYSFS_CPU0_AVAILABLE_FREQUENCIES cannot be found!"
	handlerError.sh "log" "1" "halt" "handlerCpuFreqScalFrequencies.sh"
	exit 1
fi

if [ ! -f $SYSFS_CPU0_SET_SPEED ]; then
	showInfo "FATAL: $SYSFS_CPU0_SET_SPEED cannot be found!"
	handlerError.sh "log" "1" "halt" "handlerCpuFreqScalFrequencies.sh"
	exit 1
fi

available_frequencies=`cat $SYSFS_CPU0_AVAILABLE_FREQUENCIES`
CPU_MAX_AVAIL_FREQ=$(for word in $available_frequencies; do echo $word; done | tail -1)
handlerSysFs.sh "set" $SYSFS_CPU0_MAX_FREQ $CPU_MAX_AVAIL_FREQ
echo "INFO: We have set max available frequency to $CPU_MAX_AVAIL_FREQ"

# Only in userspace governor the frequencies can be safely changed
handlerCpuFreqScalGovernors.sh "get"
handlerCpuFreqScalGovernors.sh "set" "userspace"
if [ $? -ne 0 ]; then
	showInfo "ERROR: userspace governor can not be set. The script will not continue"
	exit 1
fi

# Main script operations

if [ "$operation" = "list" ]; then

	cat $SYSFS_CPU0_AVAILABLE_FREQUENCIES

elif [ "$operation" = "set" ]; then

	if [ "$frequency_val" = "all" ]; then
		setAllFrequencies
	else
		setOneFrequency $frequency_val
	fi

elif [ "$operation" = "run" ]; then

	if [ "$frequency_val" = "all" ]; then
		setAllFrequencies "$cmd_to_execute"
	else
		setOneFrequency $frequency_val "$cmd_to_execute"
	fi

elif [ "$operation" = "set_fail" ]; then

	# Changing through unexisting frequencies
	available_frequencies=" 123456 654321 123654 456123"
	for i in $available_frequencies
	do
		showInfo "Setting Frequency to " $i
		showInfo "echo $i > $SYSFS_CPU0_SET_SPEED"
		echo $i > $SYSFS_CPU0_SET_SPEED
		cur_frequency=`cat $SYSFS_CPU0_CURRENT_FREQUENCY`
		if [ "$i" = "$cur_frequency" ]
		then
			showInfo "Fatal: Frequency was changed, unexpected!"
			error_val=1
		else
			showInfo "INFO: Frequency was not changed, good!"
			error_val=0
		fi
  done

fi

handlerCpuFreqScalGovernors.sh "restore"

exit $error_val

# End of file
