#!/bin/sh
REQUESTED_GPTIMER=$1

if [ `cat /proc/cpuinfo | grep -wc "OMAP4\|OMAP5"` -ge 1 ]; then
	if [ $REQUESTED_GPTIMER -gt 4 ] && [ $REQUESTED_GPTIMER -lt 9 ]; then
		echo "GPtimers 5-8 are not available"
		exit 0
	fi
fi

`insmod $MODDIR/gptimer_request_specific.ko gptimer_id=$REQUESTED_GPTIMER`

if [ $? -ne 0 ]; then
	echo "FATAL: timer module not loaded"
	exit 1
else
	`rmmod gptimer_request_specific`
	exit $?
fi

# End of file
