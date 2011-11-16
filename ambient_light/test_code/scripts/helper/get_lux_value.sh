#!/bin/sh

iterations=$1
count=0

while [  $count -lt $iterations ]; do
	cat $AMBIENT_LIGHT_SYSFS_PATH/lux
	let count=$count+1
done

