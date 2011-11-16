#!/bin/sh

#dependent on the following external environment variables
#AMBIENT_LIGHT_SYSFS_PATH
#AMBIENT_LIGHT_ENABLE_POWER
#AMBIENT_LIGHT_POWERON_VAL

if [ -z "$AMBIENT_LIGHT_SYSFS_PATH" ]; then
	echo "undefined \$AMBIENT_LIGHT_SYSFS_PATH"
	exit 1
fi

if [ -z "$AMBIENT_LIGHT_ENABLE_POWER" ]; then
	echo "undefined \$AMBIENT_LIGHT_ENABLE_POWER"
	exit 1
fi

if [ -z "$AMBIENT_LIGHT_POWERON_VAL" ]; then
	echo "undefined \$AMBIENT_LIGHT_POWERON_VAL"
	exit 1
fi

MINLUX=8000
MAXLUX=-8000

minmax ()
{
    if [ "$1" -lt "$MINLUX" ]; then
        MINLUX="$1"
    fi
    if [ "$1" -gt "$MAXLUX" ]; then
        MAXLUX="$1"
    fi

    local TMP1=`expr "$MAXLUX" \/ "$MINLUX"`
    local TMP2=`test "$TMP1" -gt "1" ; echo $?`
    return $TMP2
}

echo "Alternate bright and dark over the light sensor."
echo "Timeout failure will occur in one minute."

#echo $AMBIENT_LIGHT_POWERON_VAL>$AMBIENT_LIGHT_ENABLE_POWER
handlerSysFs.sh set $AMBIENT_LIGHT_ENABLE_POWER $AMBIENT_LIGHT_POWERON_VAL
handlerSysFs.sh compare $AMBIENT_LIGHT_ENABLE_POWER $AMBIENT_LIGHT_POWERON_VAL

STARTIME=`date "+%s"`
DIFTIME=0
ERROR_FLAG=1
while [ "$DIFTIME" -lt 60 ]
do
        THISLUX=`cat $AMBIENT_LIGHT_SYSFS_PATH/lux`
        minmax $THISLUX
        if [ "$?" -eq "0" ]; then
        	ERROR_FLAG=0
        	break
        fi
        NOWTIME=`date "+%s"`
        DIFTIME=`expr "$NOWTIME" - "$STARTIME"`
done

if [ "$ERROR_FLAG" -eq "0" ]
then
	echo -e "PASS: ambient light change detected\n"
else
	echo -e "FAIL: no ambient light change detected\n"
fi

exit $ERROR_FLAG
	

