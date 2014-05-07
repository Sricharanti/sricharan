#!/bin/sh

insmod $MODDIR/timer32value-smp.ko  delay=$1 iterations=$2

if [ $? -ne 0 ]; then
	echo "FATAL: timer module not loaded"
	exit 1
else
	sleep $(( $1*$2+5 ))
	rmmod timer32value_smp
	exit $?
fi

# End of file
