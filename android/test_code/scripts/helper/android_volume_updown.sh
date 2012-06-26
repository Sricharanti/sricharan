#!/bin/sh

# Android helper script to increase/decrease the volume
# Author: Leed Aguilar <leed.aguilar@ti.com>

# The scripts starts from the lowest VOL value and then it
# will increase to the max volume value, then decrease the
# minimun volume value (This operation will complete one cycle)
# The script will receive the number of cycles as a parameter
# and once the script finish it will set the volume to 50%


cycles=$1
volmaxsteps=15
counter=0

if [ $# -eq 0 ]; then
	echo -e "[volume handler] Usage: $0 <cycles>"
	exit 1
elif [ $cycles -le 0 ]; then
	echo -e "[volume handler] Specify a valid cycle number"
	exit 1
fi

# Set Initial state
while [ $counter -lt $volmaxsteps ]; do
	# input keyevent $KeyMonkeyVolumeDown
	handlerInputSubsystem.sh "keypad" "KeyCodeVolumeDown" 1 1 0
	let counter=$counter+1
done

for i in `seq 1 $cycles`; do
	counter=0
	while [ $counter -lt $volmaxsteps ]; do
		#input keyevent $KeyMonkeyVolumeUp
		handlerInputSubsystem.sh "keypad" "KeyCodeVolumeUp" 1 1 0
		let counter=$counter+1
	done
	counter=0
	while [ $counter -lt $volmaxsteps ]; do
		#input keyevent $KeyMonkeyVolumeDown
		handlerInputSubsystem.sh "keypad" "KeyCodeVolumeDown" 1 1 0
		let counter=$counter+1
	done
done

# set 50% volumen value and exit
counter=0
while [ $counter -lt 8 ]; do
	#input keyevent $KeyMonkeyVolumeUp
	handlerInputSubsystem.sh "keypad" "KeyCodeVolumeUp" 1 1 0
	let counter=$counter+1
done

exit 0

