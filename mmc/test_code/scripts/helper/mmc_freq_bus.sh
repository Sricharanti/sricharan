#!/bin/bash

#####################################################
# Name: mmc_freq_bus.sh
# Description: Helper script app to test for DDR,
#              Voltage and Clock Divider setting
# Usage
#	# mmc_freq_bus.sh <mmc reg file> <DDR> <CLKD> <VOLT>
# Eg 1: To check DDR not set, CLK=2 and VOLT=3.0 for SD card.
#       # mmc_freq_bus.sh /d/mmc1/regs 0 2 3.0
#
# Eg 2: To check DDR set, CLKD=3 and VOLT=1.8 for eMMC
#       # mmc_freq_bus.sh /d/mmc0/regs 1 3 1.8
####################################################

REGS_FILE=$1
DDR_DESIRED=$2
CLKDIV_DESIRED=$3
VOLT_DESIRED=$4
echo VOLT_DESIRED=$VOLT_DESIRED

MMC_VOLT[5]=1.8
MMC_VOLT[6]=3.0
MMC_VOLT[7]=3.3

CON_REG=$(cat $REGS_FILE | grep "CON:" | awk '{print$2}')
echo CON_REG=$CON_REG
DDR_BIT=$(( ($CON_REG >> 19) & 0x1))
echo DDR_BIT=$DDR_BIT

if [ $DDR_BIT -ne $DDR_DESIRED ]; then
	echo "DDR Test Failed"
	exit 1
fi

HCTL_REG=$(cat $REGS_FILE | grep "HCTL:" | awk '{print$2}')
echo HCTL_REG=$HCTL_REG
VOLT=$(( ($HCTL_REG >> 9) & 0x7))
echo VOLT=$VOLT
MMC_VOLT_LOCAL=$(echo ${MMC_VOLT[$VOLT]})
if [ "$VOLT_DESIRED" != $MMC_VOLT_LOCAL ]; then
	echo "VOLT Test Failed"
	exit 1
fi

SYSCTL_REG=$(cat $REGS_FILE | grep "SYSCTL" | awk '{print$2}')
echo SYSCTL=$SYSCTL_REG
CLKD=$(( ($SYSCTL_REG >> 6) & 0x3FF))
echo CLKD=$CLKD
if [ $CLKDIV_DESIRED -ne $CLKD ]; then
	echo "DIV test failed"
	exit 1
fi

echo "test pass."
echo "DDR_BIT=$DDR_BIT"
echo "CLKD=$CLKD"
echo "VOLT=$MMC_VOLT_LOCAL"
unset REGS_FILE
unset CON_REG
unset DDR_BIT
unset SYSCTL_REG
unset CLKD
unset DDR_DESIRED
unset CLKDIV_DESIRED
unset VOLT_DESIRED
unset VOLT
unset MMC_VOLT
unset MMC_VOLT_LOCAL

exit 0
