#!/bin/sh

# Android helper script to perform play/pause
# Author: Leed Aguilar <leed.aguilar@ti.com>

# The play/pause will be executed with an interval delay
# specified by the user, this process will be called a
# cycle. The script will receive the number of cycles and
# the interval delay value as parameters

# !!! The scripts needs as start condition that the playback
# is being executed

cycles=$1
delay=$2
counter=0

if [ $# -eq 0 ]; then
	echo -e "[play/pause script] Usage: $0 <cycles> <delay>"
	exit 1
elif [ $cycles -le 0 ] ; then
	echo -e "[play/pause script] Specify a valid cycle number"
	exit 1
elif [ $cycles -lt 0 ] ; then
	echo -e "[play/pause script] Specify a valid delay number"
	exit 1
fi

# Execute the play/pause operations
while [ $counter -lt $cycles ]; do
		input keyevent $KeyMonkeyPlayPause
		sleep $delay
		let counter=$counter+1
done

exit 0
