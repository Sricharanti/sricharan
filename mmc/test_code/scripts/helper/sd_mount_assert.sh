#~/bin/bash
###############################################################
# Name: sd_mount_assert.sh
# Description: Helper function to check if SD card is mounted
#		at correct location or not.
# Usage:  # sd_mount_assert /mnt/ext_sdcard 1
#	    Returns 0 if SD card mounted properly. 1 if is not.
#
#	  # sd_mount_assert /mnt/ext_sdcard 0
#	    Returns 1 if SD card is mounted properly. 0 if not.
# Author: Viswanath, Puttagunta
###############################################################

MOUNT_POINT=$1
MOUNTED=$2

if [ $MOUNTED = "1" ]; then
# Make sure SD card is properly mounted
	if [ -z "$(mount | grep "$MOUNT_POINT")" ]; then
		echo "SD card not mounted"
		exit 1
	fi
	echo "SD Card Mounted"
	exit 0
fi

# Make sure SD card is not mounted
if [ -n "$(mount | grep "$MOUNT_POINT")" ]; then
        echo "SD card mounted"
	exit 1
fi
echo "SD Card not mounted"
exit 0
