############################################################################
# Scenario: L_DD_OSKERNEL_0007_0001
# Author  : Mariia Nagul
# Date    : Feb 17, 2012
# Testing : Kernel support
###############################################################################

# Begin L_DD_OSKERNEL_0007_0001

    preemption=$(cat $KDIR/.config | grep CONFIG_PREEMPT= | sed "s/CONFIG_PREEMPT=//")
    if [ $preemption == "y" ]; then
		echo "Preemption enabled : Test PASS" && export PREEMPTION="PASS" && exit 0
    else
		echo "Preemption disabled: Test UNTESTED" && export PREEMPTION="UNTESTED"  && exit 1
    fi


# End L_DD_OSKERNEL_0007_0001
