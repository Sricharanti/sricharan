#!/bin/sh

#
#  Smart Reflex Nvalue Transitions Statistics handler
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

UTILS_DIR_TMP="../tmp"

# =============================================================================
# Variables
# =============================================================================

operation=$1
pwrdm=$2
error_val=0
nValue=0

# =============================================================================
# Functions
# =============================================================================

# Prints a message with a specific format
# @ Function: showInfo
# @ Parameters: <message to display>
# @ Return: None
showInfo() {
	message="$@"
	echo "[ handlerNvalueTransitionStats ] $message"
}

# Set nValue
# @ Function: modifyNvalue
# @ Parameters: hex variable nValue
# @ Return: nValue after increment-decrement-no modify
modifyNvalue() {
	enterNvalue=$1
	if [ $operation = "inc" ]; then
		nValue=$(($nValue + 0x11))
	elif [ $operation = "dec" ]; then
		nValue=$(($nValue - 0x11))
	elif [ $operation = "default" ]; then
		nValue=$nValue
	else
		showInfo "modifyNvalue call with unknown operation."
	fi
}

# Setup SmartReflex for Mpu domain
# @ Function: setupSmartReflexMpu
# @ Parameters: operation type
# @ Return: None
setupSmartReflexMpu() {
if [ "$operation" = "save" ]; then
	showInfo "Saving nValues mpu domain."
	nValue=`cat /d/smartreflex/smartreflex_mpu/nvalue/volt_1250000`
	echo $nValue > $UTILS_DIR_TMP/pts.sr_mpu.volt_1250000
	nValue=`cat /d/smartreflex/smartreflex_mpu/nvalue/volt_1060000`
	echo $nValue > $UTILS_DIR_TMP/pts.sr_mpu.volt_1060000
elif [ "$operation" = "default" ] || [ "$operation" = "inc" ] || [ "$operation" = "dec" ]; then
	nValue=`cat $UTILS_DIR_TMP/pts.sr_mpu.volt_1250000`
	modifyNvalue "$nValue"
	printf "volt_1250000 = %x\n" $(($nValue))
	echo $nValue > /d/smartreflex/smartreflex_mpu/nvalue/volt_1250000

	nValue=`cat $UTILS_DIR_TMP/pts.sr_mpu.volt_1060000`
	modifyNvalue "$nValue"
	printf "volt_1060000 = %x\n" $(($nValue))
	echo $nValue > /d/smartreflex/smartreflex_mpu/nvalue/volt_1060000
fi
}

# Setup SmartReflex for Mm domain
# @ Function: setupSmartReflexMm
# @ Parameters: operation type
# @ Return: None
setupSmartReflexMm() {
if [ "$operation" = "save" ]; then
	showInfo "Saving nValues mm domain."
	nValue=`cat /d/smartreflex/smartreflex_mm/nvalue/volt_1120000`
	echo $nValue > $UTILS_DIR_TMP/pts.sr_mm.volt_1120000
	nValue=`cat /d/smartreflex/smartreflex_mm/nvalue/volt_1025000`
	echo $nValue > $UTILS_DIR_TMP/pts.sr_mm.volt_1025000
	nValue=`cat /d/smartreflex/smartreflex_mm/nvalue/volt_880000`
	echo $nValue > $UTILS_DIR_TMP/pts.sr_mm.volt_880000
elif [ "$operation" = "default" ] || [ "$operation" = "inc" ] || [ "$operation" = "dec" ]; then
	nValue=`cat $UTILS_DIR_TMP/pts.sr_mm.volt_1120000`
	modifyNvalue "$nValue"
	printf "volt_1120000 = %x\n" $(($nValue))
	echo $nValue > /d/smartreflex/smartreflex_mm/nvalue/volt_1120000

	nValue=`cat $UTILS_DIR_TMP/pts.sr_mm.volt_1025000`
	modifyNvalue "$nValue"
	printf "volt_1025000 = %x\n" $(($nValue))
	echo $nValue > /d/smartreflex/smartreflex_mm/nvalue/volt_1025000

	nValue=`cat $UTILS_DIR_TMP/pts.sr_mm.volt_880000`
	modifyNvalue "$nValue"
	printf "volt_880000 = %x\n" $(($nValue))
	echo $nValue > /d/smartreflex/smartreflex_mm/nvalue/volt_880000
fi
}

# Setup SmartReflex for Core domain
# @ Function: setupSmartReflexCore
# @ Parameters: operation type
# @ Return: None
setupSmartReflexCore() {
if [ "$operation" = "save" ]; then
	showInfo "Saving nValues core domain."
	nValue=`cat /d/smartreflex/smartreflex_core/nvalue/volt_1040000`
	echo $nValue > $UTILS_DIR_TMP/pts.sr_core.volt_1040000
elif [ "$operation" = "default" ] || [ "$operation" = "inc" ] || [ "$operation" = "dec" ]; then
	nValue=`cat $UTILS_DIR_TMP/pts.sr_core.volt_1040000`
	modifyNvalue "$nValue"
	printf "volt_1040000 = %x\n" $(($nValue))
	echo $nValue > /d/smartreflex/smartreflex_core/nvalue/volt_1040000
fi
}

# =============================================================================
# Main
# =============================================================================

handlerError.sh "test"
if [ $? -eq 1 ]; then
	exit 1
fi

if [ "$pwrdm" = "smartreflex_mpu" ]; then
	setupSmartReflexMpu
elif [ "$pwrdm" = "smartreflex_mm" ]; then
	setupSmartReflexMm
elif [ "$pwrdm" = "smartreflex_core" ]; then
	setupSmartReflexCore
elif [ "$pwrdm" = "all" ]; then
	setupSmartReflexMpu
	setupSmartReflexMm
	setupSmartReflexCore
else
	showInfo "FATAL: Unknown operation $operation ."
fi

exit $error_val

# End of file
