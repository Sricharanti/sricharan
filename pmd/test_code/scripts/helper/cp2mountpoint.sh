#!/bin/sh

# parameters
mountpoint=$1
data=$2

# Verify mount point exist
if [ ! -d $mountpoint ]; then
	echo "ERROR: $mountpoint does not exits"
	exit 1
fi

# Start data transfer
echo "Starting data transfer to $mountpoint"
cp $data $mountpoint
sync
echo "Data transfer completed"
exit 0
