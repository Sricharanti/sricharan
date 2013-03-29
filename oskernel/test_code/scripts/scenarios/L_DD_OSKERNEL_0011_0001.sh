#!/bin/bash -x
############################################################################
# Scenario: L_DD_OSKERNEL_0011_0001
# Author  : Mariia Nagul
# Date    : Feb 17, 2012
# Testing : Kernel support
###############################################################################

# Begin L_DD_OSKERNEL_0011_0001

    aeabi=$(cat $KDIR/.config | grep CONFIG_AEABI | sed "s/CONFIG_AEABI[a-zA-Z0-9]*=//")
    oabi_compat=$(cat $KDIR/.config | grep CONFIG_OABI_COMPAT | sed "s/CONFIG_OABI_COMPAT[a-zA-Z0-9]*=//")
    binder=$(cat $KDIR/.config | grep BINDER | sed "s/CONFIG_[a-zA-Z0-9_]*BINDER[a-zA-Z0-9_]*=//")
    low_memory_killer=$(cat $KDIR/.config | grep LOW_MEMORY_KILLER | sed "s/CONFIG_[a-zA-Z0-9_]*LOW_MEMORY_KILLER[a-zA-Z0-9_]*=//")
    if [ $aeabi == "y" ] && [ $oabi_compat == "y" ]  && [ $binder == "y" ] && [ $low_memory_killer == "y" ]; then
	export KERNEL_SUPPORT="PASS"  && echo "Kernel  support Test PASS"  && exit 0
    else
	export KERNEL_SUPPORT="FAIL" && echo "Kernel support not configured Test FAIL" && exit 1
    fi

# End L_DD_OSKERNEL_0011_0001
