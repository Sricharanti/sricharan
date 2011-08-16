#!/bin/bash

#
# TODO
# 1. Include "all" parameter to set all domains at once
#

# =============================================================================
# Variables
# =============================================================================

LOCAL_OPERATION=$1
LOCAL_DOMAIN=$2
LOCAL_ERROR=0

# =============================================================================
# Functions
# =============================================================================

scriptUsage() {
	echo -e "\nScript usage:\n"
	echo -e "handlerSmartReflex.sh {enable|disable} [ ${sr_domain[*]} ] -or- all\n"
	exit 1
}

showInfo() {
	echo "[ handlerSmartReflex ] $1"
}

# =============================================================================
# Main
# =============================================================================

handlerError.sh "test"
if [ $? -eq 1 ]; then
	exit 1
fi

# Define which Architecture is being used
if [ `cat /proc/cpuinfo | grep -ic OMAP4` -gt 0 ]; then
		LOCAL_SR_ENTRIES=($SR_CORE_AUTOCOMP $SR_IVA_AUTOCOMP $SR_MPU_AUTOCOMP)
		LOCAL_SR_DOMAIN=(core iva mpu)
		showInfo "OMAP4 Architecture detected"
	elif [ `cat /proc/cpuinfo | grep -ic Zoom3` -gt 0 ]; then
		LOCAL_SR_ENTRIES=($SR_VDD1_AUTOCOMP $SR_VDD2_AUTOCOMP)
		LOCAL_SR_DOMAIN=(vdd1 vdd2)
		showInfo "OMAP3 Architecture detected"
	else
		showInfo "FATAL: Architecture not detected" 1>&2
		exit 1
fi


# Define Script Usage and validate all parameters
if [ $# -ne 2 ]; then
		showInfo "ERROR: number of parameters is invalid" 1>&2
		scriptUsage
fi

if [ $LOCAL_OPERATION = "enable" ]; then
		LOCAL_STATUS=$PM_ENABLE
	elif [ $LOCAL_OPERATION = "disable" ]; then
		LOCAL_STATUS=$PM_DISABLE
	else
		showInfo "ERROR: "$LOCAL_OPERATION" is an invalid parameter" 1>&2
		scriptUsage
fi

if [ `echo ${LOCAL_SR_DOMAIN[*]} | grep -ic $LOCAL_DOMAIN` -eq 0  ]; then
	showInfo "ERROR: "$LOCAL_DOMAIN" is an invalid parameter" 1>&2
	showInfo "ERROR: valid domain parameters are <${LOCAL_SR_DOMAIN[*]}>" 1>&2
	scriptUsage
fi

# Verify that all sysfs entries for SmartReflex exists

handlerDebugFileSystem.sh "mount"

for sr_entry in ${LOCAL_SR_ENTRIES[*]}; do
	if [ ! -f $sr_entry ]; then
		showInfo "FATAL: $sr_entry cannot be found" 1>&2
		LOCAL_ERROR=1
	fi
done

if [ $LOCAL_ERROR -eq 1 ]; then
	handlerError.sh "log" "1" "halt" "handlerSmartReflex.sh"
	handlerDebugFileSystem.sh "umount"
	exit $LOCAL_ERROR
fi

# Set SmartReflex autocompensation

for index in ${!LOCAL_SR_DOMAIN[*]}; do
	if [ "$LOCAL_DOMAIN" = ${LOCAL_SR_DOMAIN[$index]} ]; then
		showInfo "Setting SmartReflex autocompensation for ${LOCAL_SR_ENTRIES[$index]} domain"
		handlerSysFs.sh "set"  ${LOCAL_SR_ENTRIES[$index]} $LOCAL_STATUS
		handlerSysFs.sh "compare"  ${LOCAL_SR_ENTRIES[$index]} $LOCAL_STATUS
		if [ $? -ne 0 ]; then
			showInfo "ERROR: ${LOCAL_SR_ENTRIES[$index]} domain was not set for SmartReflex" 1>&2
			LOCAL_ERROR=1
		fi
	fi
done

if [ $LOCAL_ERROR -eq 1 ]; then
        handlerError.sh "log" "1" "halt" "handlerSmartReflex.sh"
        handlerDebugFileSystem.sh "umount"
        exit $LOCAL_ERROR
fi

handlerDebugFileSystem.sh "umount"
exit $LOCAL_ERROR

# End of file
