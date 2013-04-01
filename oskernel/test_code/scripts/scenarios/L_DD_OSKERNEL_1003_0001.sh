#!/bin/bash -x

	KDIR_MEMINFO="$KDIR/fs/proc/meminfo.c"
	cat $KDIR_MEMINFO | grep mmap; [ $? -ne 0 ]  && echo "Test FAIL" && exit 1
	adb shell "cat /proc/meminfo"; [ $? -ne 0 ] && echo "Test FAIL" && exit 1 ||  echo "Test PASS" && exit 0


