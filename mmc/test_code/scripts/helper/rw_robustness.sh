#!/bin/bash
##########################################################
# Name:         rw_robustness.sh
# Description:
#		Read/Write robustness testing for Mass Storage
# Usage:
#		./rw_robustness read/write <folder> <duration>
#			<bs> <count> <drop_caches>
# Author:  	Viswanath, Puttagunta
#########################################################

OPERATION=$1
FOLDER=$2
DURATION=$3
BLOCK_SIZE=$4
COUNT=$5
DROPCACHES=$6

dd if=/dev/urandom of=$FOLDER/tmp.file bs=$BLOCK_SIZE count=$COUNT
NOWTIME=$(date "+%s")
ENDTIME=$(($NOWTIME + $DURATION))

if [ "$OPERATION" = "read" ]; then
	while [ "$NOWTIME" -lt "$ENDTIME" ]; do
		NOWTIME=$(date "+%s")
		echo "NOWTIME=$NOWTIME, ENDTIME=$ENDTIME"
		if [ "$DROPCACHES" = "1" ]; then
			echo 1 > /proc/sys/vm/drop_caches && sync
		fi
		dd if=$FOLDER/tmp.file of=/dev/null bs=$BLOCK_SIZE count=$COUNT
		if [ $? != "0" ]; then
			exit 1
		fi
	done
	exit 0
fi

if [ "$OPERATION" = "write" ]; then
	while [ "$NOWTIME" -lt "$ENDTIME" ]; do
		NOWTIME=$(date "+%s")
		echo "NOWTIME=$NOWTIME, ENDTIME=$ENDTIME"
		if [ "$DROPCACHES" = "1" ]; then
			echo 1 > /proc/sys/vm/drop_caches && sync
		fi
		dd if=/dev/zero of=$FOLDER/tmp.file bs=$BLOCK_SIZE count=$COUNT
		if [ $? != "0" ]; then
			exit 1
		fi
	done
	exit 0
fi
echo "INVALID OPERATION: $OPERATION"
exit 1
