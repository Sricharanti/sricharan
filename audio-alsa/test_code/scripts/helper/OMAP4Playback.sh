#!/bin/sh

handlerError.sh "test"
if [ $? -eq 1 ]; then
	exit 1
fi

if [ $# -lt 4 ]; then
	echo "Usage: $0 <Frontend> <Backend> <Port> <Filename> <Duration>"
	echo " Frontend: 'Multimedia', 'MultimediaLP', 'Tones', 'Voice'"
	echo " Backend: 'Headset', 'Handsfree', 'Earpiece'"
	echo " Port: 'hw:0,0', 'plughw:0,0', ..."
	echo " Duration: 1, 2, ... (in secs)"
	exit 1
fi

frontend=$1
backend=$2
port=$3
filename=$4
duration=$5

$TESTSCRIPT/OMAP4ConfigureOutput.sh $frontend $backend Enable || exit 1
if [ "$duration" = "" ]; then
	aplay -D $port $filename || exit 1
else
	aplay -D $port -d $duration $filename || exit 1
fi
$TESTSCRIPT/OMAP4ConfigureOutput.sh $frontend $backend Disable || exit 1
