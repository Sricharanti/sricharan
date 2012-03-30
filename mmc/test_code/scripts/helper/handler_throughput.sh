#!/bin/bash
##########################################################
# Name:		hander_throughput.sh
# Description:	Helper script to measure throughput for
#		read and write. Does not mount/unmount
#		partitions. Assumed necessary partition
#		is already mounted at correct location
# Usage:	./handler_throughput <device> <folder>
#		Eg:
#		./handler_throughput /dev/block/mmcblk0p10 /data
# Author:	Viswanath, Puttagunta
# Date:		30 Mar, 2012
##########################################################
DEVICE=$1
FOLDER=$2

BLOCKSIZE=1024000
COUNT=200
ITERATIONS=5

#Usage
#iterate_bw <i/p> <o/p> <drop_caches:0/1>
#Eg: iterate_bw /dev/zero /mnt/ext_sdcard/zero.bin 1
function iterate_bw()
{
	TIME=0
	for ((i=0; i < $ITERATIONS; i++)); do
		echo ITERATION=$i
		if [ "$3" = "1" ]; then
			echo 1 > /proc/sys/vm/drop_caches && sync
		fi
		ALL=$((time -p dd if=$1 of=$2 bs=$BLOCKSIZE count=$COUNT && sync) 2>&1)
		echo ALL=$ALL
		REAL=$(echo $ALL | cut -d' ' -f15)
		SYS=$(echo $ALL | cut -d' ' -f19)
		TIME=$(echo "$TIME + $REAL + $SYS" | bc)
		echo REAL=$REAL SYS=$SYS TIME=$TIME
	done
	BW=$(echo "($BLOCKSIZE*$COUNT*$ITERATIONS) / (($TIME)*1024*1024)" | bc)
	echo BW=$BW
}

#File System Write Throughput
iterate_bw "/dev/zero" "$FOLDER/zero.bin" 1
FS_WRITE=$BW

#File System Read Throughput
iterate_bw "$FOLDER/zero.bin" "/dev/null" 1
FS_READ=$BW

#Device Raw Read Throughput
iterate_bw "$DEVICE" "/dev/null" 1
RAW_READ=$BW

rm $FOLDER/zero.bin
echo "-------------------------------"
echo FILE SYSTEM WRITE THROUGHPUT = $FS_WRITE MBytes/sec
echo FILE SYSTEM READ THROUGHPUT = $FS_READ MBytes/sec
echo RAW READ THROUGHPUT =         $RAW_READ MBytes/sec
echo "-------------------------------"
