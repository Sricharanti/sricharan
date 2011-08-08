#!/bin/sh

#
#  CPU Governor Handler
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
cpugovernor=$2
command_line=$3

# =============================================================================
# Functions
# =============================================================================

setOneGovernor() {

	local_governor=$1
	command_to_execute=$2

	if [ -n "$command_to_execute" ]; then
		eval $command_to_execute &
	fi

	handlerSysFs.sh "set" $SYSFS_CPU0_CURRENT_GOVERNOR $local_governor
	handlerSysFs.sh "verify" $SYSFS_CPU0_CURRENT_GOVERNOR $local_governor
	if [ $? -ne 0 ]; then
		showInfo "Error: Governor < $local_governor > cannot be set"
		exit 1
	fi
	showInfo "Governor < $local_governor > was set correctly"
	wait
	sleep 5
}

setAllGovernor() {

	command_to_execute=$@
	error=0
	echo > $HCFSG_GOVERNORS_LIST_OK
	echo > $HCFSG_GOVERNORS_LIST_ERROR

	available_governors=`cat $SYSFS_CPU0_AVAILABLE_GOVERNORS`
	showInfo "Info: Available Governors are -> $available_governors"
	if [ -n "$command_to_execute" ]; then
		eval $command_to_execute &
		command_pid=`echo $!`
	fi
	while [ 1 ]; do
		for governor in $available_governors; do
			showInfo "Setting CPU Governor to $governor"
			handlerSysFs.sh "set" $SYSFS_CPU0_CURRENT_GOVERNOR $governor
			handlerSysFs.sh "verify" $SYSFS_CPU0_CURRENT_GOVERNOR $governor
			if [ $? -ne 0 ]; then
				showInfo "Error: Governor $governor cannot be set"
				echo $governor >> $HCFSG_GOVERNORS_LIST_ERROR
				error=1
			else
				showInfo "Info: Governor $governor was set correctly"
				echo $governor >> $HCFSG_GOVERNORS_LIST_OK
			fi
			# TODO: Add delay option between setting cycles
			sleep 1
		done

		if [ -n "$command_to_execute" ]; then
			test -d /proc/$command_pid || break
		else
			break
		fi
	done
	wait

	showInfo "Info: The following Governors were set correctly"
	cat $HCFSG_GOVERNORS_LIST_OK
	if [ $error -eq 1 ]; then
		showInfo "Info: The following Governors were not set correctly"
		cat $HCFSG_GOVERNORS_LIST_ERROR
		exit 1
	fi
}

getCurrentGovernor() {
	governor_saved=$1
	current_governor=`cat $SYSFS_CPU0_CURRENT_GOVERNOR`
	showInfo "Info: Current Governor -> $current_governor"

	echo $current_governor > $governor_saved
}

restoreCurrentGovernor() {
	governor_saved=$1

	if [ -f "$governor_saved" ]; then
		# TODO: Verify that the cpu governor was set correctly
		cat $governor_saved > $SYSFS_CPU0_CURRENT_GOVERNOR
		showInfo "Info: Restore to Governor -> `cat $governor_saved`"
	else
		showInfo 'Error: $governor_saved file is empty'
	fi
}

showInfo() {
	echo "[ handlerCpuGovernors ] $1"
}

# =============================================================================
# Main
# =============================================================================

handlerError.sh "test"
if [ $? -eq 1 ]; then
	exit 1
fi

# Verify that all required syfs entries are available
if [ ! -f $SYSFS_CPU0_AVAILABLE_GOVERNORS ]; then
	showInfo "FATAL: $SYSFS_CPU0_AVAILABLE_GOVERNORS cannot be found!"
	handlerError.sh "log" "1" "halt" "handlerCpuFreqScalGovernors.sh"
	exit 1
fi
if [ ! -f $SYSFS_CPU0_CURRENT_GOVERNOR ]; then
	showInfo "FATAL: $SYSFS_CPU0_CURRENT_GOVERNOR cannot be found!"
	handlerError.sh "log" "1" "halt" "handlerCpuFreqScalGovernors.sh"
	exit 1
fi

# TODO: Add script usage

if [ "$operation" = "list" ]; then

	cat $SYSFS_CPU0_AVAILABLE_GOVERNORS

elif [ "$operation" = "set" ]; then

	if [ "$cpugovernor" = "all" ]; then
		setAllGovernor
	else
		setOneGovernor $cpugovernor
	fi

elif [ "$operation" = "run" ]; then

	if [ "$cpugovernor" = "all" ]; then
		setAllGovernor "$command_line"
	else
		setOneGovernor $cpugovernor "$command_line"
	fi

elif  [ "$operation" = "get" ]; then

	getCurrentGovernor $HCFSG_CURRENT_GOVERNOR_FILE

elif  [ "$operation" = "restore" ]; then

	restoreCurrentGovernor $HCFSG_CURRENT_GOVERNOR_FILE

fi

# End of file
