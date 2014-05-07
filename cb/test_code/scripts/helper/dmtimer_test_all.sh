#!/bin/sh

`insmod $MODDIR/dmtimer_test_all.ko`

if [ $? -ne 0 ]; then
	echo "FATAL: timer module not loaded"
	exit 1
else
	`rmmod dmtimer_test_all`
	exit $?
fi

# End of file
