#!/bin/sh

if [ $# -lt 5 ]; then
	echo "Usage: $0 <Frontend> <Backend> <Port> <Filename> <Duration>"
	echo " Frontend: 'Multimedia', 'Multimedia2', 'Voice'"
	echo " Backend: 'HeadsetMic', 'OnboardMic', 'Aux/FM', 'DMic0', 'DMic1', 'DMic2'"
	echo " Port: 'hw:0,0', 'plughw:0,0', ..."
	echo " Duration: 1, 2, ... (in secs)"
	exit 1
fi

frontend=$1
backend=$2
port=$3
filename=$4
duration=$5

$TESTSCRIPT/OMAP4ConfigureInput.sh $frontend $backend Enable || exit 1
echo "Recording $duration s..."
arecord -D $port -f S16_LE -r 48000 -c 2 -d $duration $filename || exit 1
$TESTSCRIPT/OMAP4ConfigureInput.sh $frontend $backend Disable || exit 1

$TESTSCRIPT/OMAP4ConfigureOutput.sh Multimedia Headset Enable || exit 1
aplay -D plughw:0,0 $filename || exit 1
$TESTSCRIPT/OMAP4ConfigureOutput.sh Multimedia Headset Disable || exit 1
