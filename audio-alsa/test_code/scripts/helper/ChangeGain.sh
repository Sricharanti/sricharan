#!/bin/sh

control_name=$1
direction=$2
start=$3
end=$4
step=$5
delay=$6

gain=$start

if [ "$direction" = "Increase" ]; then
	while [ $gain -le $end ]
	do
		amixer cset name="$control_name" $gain
		sleep $delay
		gain=`expr $gain + $step`
	done
elif [ "$direction" = "Decrease" ]; then
	while [ $gain -ge $end ]
	do
		amixer cset name="$control_name" $gain
		sleep $delay
		gain=`expr $gain - $step`
	done
else
	echo "Invalid volume change direction '$direction'"
	exit 1
fi
