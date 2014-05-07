#!/bin/sh

REQUESTED_TYPE=$1

`insmod $MODDIR/gptimer_request.ko clock_type=$REQUESTED_TYPE`

if [ $? -ne 0 ]; then
	echo "FATAL: timer module not loaded"
	exit 1
else
	`rmmod gptimer_request`
	exit $?
fi

# End of file
