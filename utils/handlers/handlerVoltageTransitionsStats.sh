#!/bin/sh

#
#  SmartReflex Voltage Transitions handler
#
#  Copyright (c) 2013 Texas Instruments
#
#  Author: Andrii Danylov <andrii.danylov@ti.com>
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

UTILS_DIR_TMP="."

# =============================================================================
# Variables
# =============================================================================

operation=$1
voltdm=$2
error_val=0

# =============================================================================
# Functions
# =============================================================================

# Prints a message with a specific format
# @ Function: showInfo
# @ Parameters: <message to display>
# @ Return: None
showInfo() {
	message="$@"
	echo "[ handlerPowerTransitionStats ] $message"
}

# =============================================================================
# Main
# =============================================================================

handlerError.sh "test"
if [ $? -eq 1 ]; then
	exit 1
fi

if [ "$operation" = "compare" ]; then

	val_nominal=`cat $PM_VOLT/$voltdm/curr_nominal_volt`
	val_vp=`cat $PM_VOLT/$voltdm/curr_vp_volt`

	if [ $voltdm = "vdd_mpu" ]; then
		smartreflex_enab=`cat $SR_MPU_AUTOCOMP`
	elif [ $voltdm = "vdd_mm" ]; then
		smartreflex_enab=`cat $SR_IVA_AUTOCOMP`
	elif [ $voltdm = "vdd_core" ]; then
		smartreflex_enab=`cat $SR_CORE_AUTOCOMP`
	fi

	showInfo "$voltdm: Smartreflex (1-enabled,0-disabled): $smartreflex_enab"
	showInfo "$voltdm: Nominal Value : $val_nominal"
	showInfo "$voltdm: Real Value : $val_vp"
	showInfo "Verifying $voltdm: vp voltage with nominal ..."
	sleep 3

	if [ $smartreflex_enab -eq 1 ]; then
		if [ $val_nominal -eq $val_vp ]; then
			showInfo "ERROR: $voltdm voltage did not decrease"
			showInfo "TEST FAILED"
			error_val=1
		elif [ $val_nominal -gt $val_vp ]; then
			showInfo "SUCCESS: $voltdm voltage decreased"
			showInfo "TEST PASSED"
			error_val=0
		else
			showInfo "FATAL: Please review why nominal voltage smaller then real."
			error_val=1
		fi
	elif [ $smartreflex_enab -eq 0 ]; then
		if [ $val_nominal -eq $val_vp ]; then
			showInfo "SUCCESS: $voltdm voltage decreased"
			showInfo "TEST PASSED"
			error_val=0
		else
			showInfo "ERROR: $voltdm voltage did not decreased"
			showInfo "TEST FAILED"
			error_val=1
		fi
	fi

fi


exit $error_val

# End of file
