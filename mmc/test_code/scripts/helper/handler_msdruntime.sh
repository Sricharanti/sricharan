#!/bin/bash
########################################################
# Name: 	handler_msdruntime.sh
# Description:	Excersices Mass Storage driver's runtime
#		suspend/resume handlers to make sure
#		corresponding Power domain going to low
#		power states during runtime.
# Usage:	./handler_msdruntime.sh <folder> <pwr_dm>
#					<pm_count_file>
# 		Eg:
#		./handler_msdruntime.sh /data l3init_pwrdm
#					    /d/pm_debug/count
# Author:	Viswanath, Puttagunta
# Date:		Mar 30, 2012
########################################################

FOLDER=$1
PWRDM=$2
PMCOUNT=$3
RETVAL=1
# Check RET during burst writes
RETSTART=$(cat $PMCOUNT | grep ^"$PWRDM (" | cut -d',' -f3 | cut -d':' -f2)
echo RETSTART=$RETSTART
for (( i=0; i<8; i++ )); do
	echo 1 > /proc/sys/vm/drop_caches && sync
	dd if=/dev/zero of=$FOLDER/tmp.file bs=1024000 count=5
	sleep 0.5
done

RETEND=$(cat $PMCOUNT | grep ^"$PWRDM (" | cut -d',' -f3 | cut -d':' -f2)
if [ $RETEND -le $RETSTART ]; then
	echo "Power domain $PWRDM not going to RET while Write"
	rm $FOLDER/tmp.file
	exit 1
fi

# Check for RET during burst reads
RETSTART=$(cat $PMCOUNT | grep ^"$PWRDM (" | cut -d',' -f3 | cut -d':' -f2)
echo RETSTART=$RETSTART

for (( i=0; i<8; i++ )); do
	echo 1 > /proc/sys/vm/drop_caches && sync
	dd if=$FOLDER/tmp.file of=/dev/null bs=1024000 count=5
	sleep 0.5
done

RETEND=$(cat $PMCOUNT | grep ^"$PWRDM (" | cut -d',' -f3 | cut -d':' -f2)
if [ $RETEND -le $RETSTART ]; then
	echo "Power domain $PWRDM not going to RET while Read"
	rm $FOLDER/tmp.file
	exit 1
fi
rm $FOLDER/tmp.file
exit 0
