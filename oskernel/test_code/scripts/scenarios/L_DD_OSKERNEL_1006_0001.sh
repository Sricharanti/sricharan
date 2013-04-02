#!/bin/bash -x

	KDIR_EMIF="$KDIR/drivers/misc/emif.h"
	emif=`cat $KDIR_EMIF | grep "define EMIF_MAX_NUM_FREQUENCIES" | awk '{print $3}'`
	if [ "$emif" != "6" -o $? -ne 0 ]; then
	    echo "EMIF: $emif"
	    echo "INFO: Test FAIL" && exit 1
	else
	    echo "EMIF: $emif"
	    echo "INFO: Test PASS" && exit 0
	fi
