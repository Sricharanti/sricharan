#!/bin/bash
##########################################################
# Name:		handler_filegtpart.sh
# Description:  Helper script to write bigger file than
#		partition size. Will return 1 if success
#		because this is a failure. Ret 0 if fail
# Usage:	./handler_filegtpart.sh <folder>
#		Eg:
#		./handler_filegtpart.sh /data
# Author:	Viswanath, Puttagunta
# Date:		30 Mar, 2012
##########################################################
FOLDER=$1

MAXSIZE=$(df | grep "$FOLDER")
MAXSIZE=$(echo $MAXSIZE)
echo MAXSIZE=$MAXSIZE

if [ "$(echo $MAXSIZE | grep "^/")" = "" ]; then
	MAXSIZE=$(echo $MAXSIZE | cut -d' ' -f3)
else
	MAXSIZE=$(echo $MAXSIZE | cut -d' ' -f4)
fi
echo MAXSIZE=$MAXSIZE
WRITESIZE=$(( $MAXSIZE + 10000 ))

if dd if=/dev/zero of=$FOLDER/zero.bin bs=1024 count=$WRITESIZE
then
	echo "Write Successful"
	rm $FOLDER/zero.bin
	exit 1
else
	echo "Write unsuccessful"
	rm $FOLDER/zero.bin
	exit 0
fi

