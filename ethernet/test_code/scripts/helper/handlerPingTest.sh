#!/bin/bash

#  Ping stress test handler
#
#  Copyright (c) 2012 Texas Instruments
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

# =============================================================================
# Variables
# =============================================================================

ipaddr=$1
mindatasize=$2
maxdatasize=$3
stepsize=$4
iteration=$5
datasize=$mindatasize
logfile=""$ETHERNET_FILE_TMP".logfile"
statistics=""$ETHERNET_FILE_TMP".statistics"
error=0

# =============================================================================
# Functions
# =============================================================================

# Prints a message with a specific format
# @ Function: showInfo
# @ Parameters: <message to display>
# @ Return: None
showInfo() {
	messages="$@"
	echo -e "[ handlerPingTest ] $messages"
}

# Display the script usage
# @ Function: generalUsage
# @ parameters: None
# @ Return: Error flag value
generalUsage() {
	cat <<-EOF >&1

	 Script Usage:

	 $0 IPADDR MINDATASIZE MAXDATASIZE STEPSIZE ITERATIONS

	    IPADDR       = IP Address of remote host
	    MINDATASIZE  = Minimum data size
	    MAXDATASIZE  = Maximum data size
	    STEPSIZE     = Step increment of data size
	    ITERATIONS   = The number of repeats to send ping with
			   current data size

	EOF
}

# Script clean up activities
# @ Function: clean_tasks
# @ parameters: None
# @ Return: none
clean_tasks() {
        showInfo "Executing clean up tasks"
        # Clear tmp folder
        if [ -d $ETHERNET_DIR_TMP ]; then
                rm -rf $ETHERNET_DIR_TMP/*
        fi
}

# Clean up task exclusive for the TRAP signal
# @ Function: cleanup
# @ parameters: None
# @ Return: exit status
cleanup() {
	showInfo "Script interrupt signal detected"
	showInfo "Aborting script execution"
	clean_tasks
	exit 0
}

# Verify is the parameter is a valid number (integer)
# @ Function: isPositiveInteger
# @ Parameters: <number>
# @ Return: Error flag value
isPositiveInteger() {
	num=$1
	if ! [[ $num =~ ^[0-9]+$ ]]; then
		showInfo "ERROR: $num is not a number" 1>&2
		return 1
	fi
}

# =============================================================================
# Pre-run
# =============================================================================

# We need a TMP folder to save our logs
if [ ! -d $ETHERNET_DIR_TMP ]; then
	showInfo "FATAL: There is no temporal folder"
	exit 1
fi

# Verify number of parameters
[ $# -ne 5 ] && generalUsage && exit 1

# Verify arguments are valid numbers
isPositiveInteger "$mindatasize" || exit 1
isPositiveInteger "$maxdatasize" || exit 1
isPositiveInteger "$stepsize"    || exit 1
isPositiveInteger "$iteration"   || exit 1

# =============================================================================
# Main
# =============================================================================

trap cleanup SIGHUP SIGINT SIGTERM

handlerError.sh "test"
if [ $? -eq 1 ]; then
	exit 1
fi

showInfo "Starting test execution ..." && sleep 1

while [ $datasize -le $maxdatasize ]; do
	for i in `seq 1 $iteration`; do
		ping -c 1 -s $datasize $ipaddr > $statistics
		# Save error exit status of the ping operation
		ping_err=`echo $?`
		# Print the current ping operation
		echo "" && cat $statistics | grep -r "PING"
		# Verify if the the Network is unreachable
		cat $statistics | grep -r "received"
		[ `echo $?` -eq 0 ] || packets_received=0 && \
			packets_received=`cat $statistics | \
				grep -r "received" | awk '{print$4}'`
		# Evaluate possible errors on the ping operation
		if [ $ping_err -ne 0 ] || [ $packets_received -eq 0 ]; then
			error=1
			echo -e `cat $statistics | grep -r PING` >> $logfile
			echo -e "Size: $datasize Iteration: $i\n" >> $logfile
		fi
	done
	let datasize=$datasize+$stepsize
done

# Report failures
if [ $error -eq 1 ]; then
	sleep 1 && showInfo "Errors detected during script execution\n"
	echo -e "=================== Error report ===================\n"
	cat $logfile
	echo -e "====================================================\n"
	clean_tasks
	exit 1
fi

# Looks like everything went well
sleep 1 && showInfo "All ping tests passed"
clean_tasks
exit 0

# End of file
