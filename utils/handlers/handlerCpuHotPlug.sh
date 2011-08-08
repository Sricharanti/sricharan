#!/bin/sh

# =============================================================================
# Variables
# =============================================================================

LOCAL_OPERATION=$1
LOCAL_TIME=$2
LOCAL_COMMAND=$3

LOCAL_ERROR=0

# =============================================================================
# Functions
# =============================================================================

cpuHotPlug() {

	LOCAL_COMMAND_LINE=$@
	LOCAL_ERROR=0
	LOCAL_COUNT=1

	if [ -n "$LOCAL_COMMAND_LINE" ]; then
		$LOCAL_COMMAND_LINE &
		LOCAL_COMMAND_PID=`echo $!`
	fi

	while [ 1 ]; do

		echo
		rem=$(( $LOCAL_COUNT % 2 ))
		if [ $rem -eq 1 ]
		then
			echo "[ handlerCpuHotPlug ] CPU1 ON | Frequency $LOCAL_TIME seconds"
			handlerSysFs.sh "set" $SYSFS_CPU1_ONLINE "1"
			handlerSysFs.sh "compare" $SYSFS_CPU1_ONLINE "1"
			if [ $? -ne 0 ]; then
				echo "[ handlerCpuHotPlug ] FATAL: Not able to set CPU1 ON"
				handlerError.sh "log" "1" "halt" "handlerCpuHotPlug.sh"
				exit 1
			fi
		else
			echo "[ handlerCpuHotPlug ] CPU1 OFF | Frequency $LOCAL_TIME seconds"
			handlerSysFs.sh "set" $SYSFS_CPU1_ONLINE "0"
			handlerSysFs.sh "compare" $SYSFS_CPU1_ONLINE "0"
			if [ $? -ne 0 ]; then
				echo "[ handlerCpuHotPlug ] FATAL: Not able to set CPU1 OFF"
				handlerError.sh "log" "1" "halt" "handlerCpuHotPlug.sh"
				exit 1
			fi
		fi

		if [ -n "$LOCAL_COMMAND_LINE" ]; then
			test -d /proc/$LOCAL_COMMAND_PID
			if [ $? -ne 0 ]; then
				# get exit code of background process
				wait $LOCAL_COMMAND_PID
				if [ $? -ne 0 ]; then
					echo "[ handlerCpuHotPlug ] FATAL: failure detected in"\
						" background process"
					echo "[ handlerCpuHotPlug ] FATAL: <$LOCAL_COMMAND_LINE>"\
						" command failed"
					handlerError.sh "log" "1" "halt" "handlerCpuHotPlug.sh"
					exit 1
				fi
				break
			fi
		fi

		sleep $LOCAL_TIME

		LOCAL_COUNT=`expr $LOCAL_COUNT + 1`

	done

	wait

}


# =============================================================================
# Main
# =============================================================================

handlerError.sh "test"
if [ $? -eq 1 ]; then
	exit 1
fi

if [ ! -f $SYSFS_CPU0_ONLINE ]; then
	echo "[ handlerCpuHotPlug ] FATAL: $SYSFS_CPU0_ONLINE cannot be found!"
	handlerError.sh "log" "1" "halt" "handlerCpuHotPlug.sh"
	exit 1
fi

if [ ! -f $SYSFS_CPU1_ONLINE ]; then
	echo "[ handlerCpuHotPlug ] FATAL: $SYSFS_CPU1_ONLINE cannot be found!"
	handlerError.sh "log" "1" "halt" "handlerCpuHotPlug.sh"
	exit 1
fi

# Verify dual core support
handlerSysFs.sh "set" $SYSFS_CPU1_ONLINE "1"
handlerSysFs.sh "compare" $SYSFS_CPU_ONLINE "0-1"
if [ $? -ne 0 ]; then
	echo "[ handlerCpuHotPlug ] FATAL: No dual core support"
	handleError.sh "log" "1" "halt" "handlerCpuHotPlug.sh"
	exit 1
fi

if [ "$LOCAL_OPERATION" = "run" ]; then

	cpuHotPlug $LOCAL_COMMAND

fi

exit $LOCAL_ERROR

# End of file
