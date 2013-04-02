#!/bin/bash -x

	KDIR_EMIF="$KDIR/arch/arm/mach-omap2/include/mach/emif.h"
	emif=`cat $KDIR_EMIF | grep "define EMIF_NUM_INSTANCES" | sed "s/\#define EMIF_NUM_INSTANCES //"`
	if [ "$emif" != "2" -o $? -ne 0 ]; then
	    echo "EMIF: $emif"
	    echo "INFO: Test FAIL" && exit 1
	else
	    echo "EMIF: $emif"
	    echo "INFO: Test PASS" && exit 0
	fi


