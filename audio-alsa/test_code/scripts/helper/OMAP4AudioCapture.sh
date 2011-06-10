#!/bin/sh

if [ $# -lt 6 ]; then
	echo "Usage: $0 <Frontend> <Backend> <Port> <Format> <Rate> <Channels> [<BufferTime>]"
	echo " Frontend: 'Multimedia', 'Multimedia2', 'Voice'"
	echo " Backend: 'HeadsetMic', 'OnboardMic', 'Aux/FM', 'DMic0', 'DMic1', 'DMic2'"
	echo " Port: 'hw:0,0', 'plughw:0,0', ..."
	echo " Format: 'S16_LE', 'S32_LE'"
	echo " Rate: 8000, 16000, 44100, 48000"
	echo " Channels: 1, 2, ..."
	echo " Buffer Time (optional): 5000, 10000, ... (in us)"
	exit 1
fi

frontend=$1
backend=$2
port=$3
format=$4
rate=$5
channels=$6
buffer_time=$7

echo "*****************************************************************"
echo " Audio Capture "
echo " - Frontend: $frontend "
echo " - Backend: $backend "
echo " - Port: $port "
echo " - Configuration: Format:$format Rate:$rate Channels:$channels"
echo "*****************************************************************"

$TESTSCRIPT/OMAP4ConfigureInput.sh $frontend $backend Enable || exit 1
echo "Recording 5s..."
if [ "$buffer_time" = "" ]; then
	arecord -D $port -f $format -r $rate -c $channels -d 5 $TMPBASE/record.wav || exit 1
else
	arecord -D $port -f $format -r $rate -c $channels -d 5 --buffer-time=$buffer_time $TMPBASE/record.wav || exit 1
fi
echo "Done"
$TESTSCRIPT/OMAP4ConfigureInput.sh $frontend $backend Disable || exit 1

$TESTSCRIPT/OMAP4ConfigureOutput.sh Multimedia Headset Enable || exit 1
aplay -D plughw:0,0 $TMPBASE/record.wav || exit 1
$TESTSCRIPT/OMAP4ConfigureOutput.sh Multimedia Headset Disable || exit 1
