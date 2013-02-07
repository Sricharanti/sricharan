#!/bin/bash
########################################################
# Name: 	handler_msd_rw.sh
# Description:	Excersices Mass Storage driver's read&write
# Usage:	./handler_msd_rw.sh <folder> <rw_op>
# 		Eg:
#		./handler_msd_rw.sh /data "1"
# Author:	Andrii Danylov
# Date:		02/04/2013
########################################################

RW_OP=$1
FOLDER=$2

for (( i=0; i<8; i++ )); do

	if [ "$RW_OP" = "1" ]; then
	echo 1 > /proc/sys/vm/drop_caches && sync
	dd if=/dev/zero of=$FOLDER/tmp.file bs=1024000 count=5
	elif [ "$RW_OP" = "0" ]; then
	dd if=$FOLDER/tmp.file of=/dev/null bs=1024000 count=5
	fi
	sleep 0.5
done

if [ "$RW_OP" = "2" ]; then
rm $FOLDER/tmp.file
fi

exit 0
