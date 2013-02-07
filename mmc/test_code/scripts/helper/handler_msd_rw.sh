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

FOLDER=$1
RW_OP=$2

for (( i=0; i<8; i++ )); do
	echo 1 > /proc/sys/vm/drop_caches && sync
	if [ RW_OP -eq "1" ];	#write op
	dd if=/dev/zero of=$FOLDER/tmp.file bs=1024000 count=5
	else			#read
	dd if=$FOLDER/tmp.file of=/dev/null bs=1024000 count=5
	rm $FOLDER/tmp.file
	fi
	sleep 0.5
done
exit 0
