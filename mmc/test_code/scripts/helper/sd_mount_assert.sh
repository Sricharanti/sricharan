#~/bin/bash
###############################################################
# Name: sd_mount_assert.sh
# Description: Helper function to check if SD card is mounted
#		at correct location
# Usage: Make sure SD card is plugged in and Android is booted
#        # sd_mount_assert
# Author: Viswanath, Puttagunt
###############################################################

if [ -z "$(mount | grep "/mnt/ext_sdcard")" ]; then
	echo "SD card not mounted"
	exit 1
fi
echo "SD card mounted"
exit 0
