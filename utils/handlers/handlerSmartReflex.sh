#!/bin/bash

#
#  Handler SmartReflex Autocompensation
#
#  Copyright (c) 2011 Texas Instruments
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License as
#  published by the Free Software Foundation; either version 2 of the
#  License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
#  USA
#

# =============================================================================
# Variables
# =============================================================================

operation=$1
domain=$2
error_status=0

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
		sr_entries=($SR_CORE_AUTOCOMP $SR_IVA_AUTOCOMP $SR_MPU_AUTOCOMP)
		sr_domain=(core iva mpu)
		showInfo "OMAP4 Architecture detected"
	elif [ `cat /proc/cpuinfo | grep -ic Zoom3` -gt 0 ]; then
		sr_entries=($SR_VDD1_AUTOCOMP $SR_VDD2_AUTOCOMP)
		sr_domain=(vdd1 vdd2)
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

if [ $operation = "enable" ]; then
	status=$PM_ENABLE
	action="Enabling"
elif [ $operation = "disable" ]; then
	status=$PM_DISABLE
	action="Disabling"
else
	showInfo "ERROR: $operation is an invalid parameter" 1>&2
	scriptUsage
fi

if [ `echo ${sr_domain[*]} | grep -wc $domain` -eq 0 -a \
	"$domain" != "all" ]; then
	showInfo "ERROR: "$domain" is an invalid parameter" 1>&2
	scriptUsage
fi

# Verify that all sysfs entries for SmartReflex exists

handlerDebugFileSystem.sh "mount"

for sr_entry in ${sr_entries[*]}; do
	if [ ! -f $sr_entry ]; then
		showInfo "FATAL: $sr_entry cannot be found" 1>&2
		error_status=1
	fi
done

if [ $error_status -eq 1 ]; then
	handlerError.sh "log" "1" "halt" "handlerSmartReflex.sh"
	#handlerDebugFileSystem.sh "umount"
	exit $error_status
fi

# Set SmartReflex autocompensation

if [ $domain = "all" ]; then
	for index in ${!sr_domain[*]}; do
		showInfo "$action SmartReflex autocompensation for ${sr_domain[$index]} domain"
		handlerSysFs.sh "set"  ${sr_entries[$index]} $status
		handlerSysFs.sh "verify"  ${sr_entries[$index]} $status
		if [ $? -ne 0 ]; then
			showInfo "ERROR: ${sr_domain[$index]} domain was not set for SmartReflex" 1>&2
			error_status=1
		fi
	done
# Set SmartReflex autocompensation for a specific domain
else
	for index in ${!sr_domain[*]}; do
		if [ "$domain" = ${sr_domain[$index]} ]; then
			showInfo "$action SmartReflex autocompensation for ${sr_domain[$index]} domain"
			handlerSysFs.sh "set"  ${sr_entries[$index]} $status
			handlerSysFs.sh "verify"  ${sr_entries[$index]} $status
			if [ $? -ne 0 ]; then
				showInfo "ERROR: ${sr_domain[$index]} domain was not set for SmartReflex" 1>&2
				error_status=1
			fi
		fi
	done
fi

if [ $error_status -eq 1 ]; then
        handlerError.sh "log" "1" "halt" "handlerSmartReflex.sh"
        #handlerDebugFileSystem.sh "umount"
        exit $error_status
fi

#handlerDebugFileSystem.sh "umount"
exit $error_status

# End of file
