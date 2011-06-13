#!/bin/sh

QUERY_DELAY=$1

`insmod $MODDIR/timer32value.ko delay=$QUERY_DELAY`

if [ $? -ne 0 ]; then
	echo "FATAL: timer module not loaded"
	exit 1
else
	`rmmod timer32value`
	exit $?
fi

# End of file
