#!/bin/sh

if [ $# -lt 6 ]; then
	echo "Usage: $0 <Frontend> <Backend> <Port> <Format> <Rate> <Channels> [<BufferTime>]"
	echo " Frontend: 'Multimedia', 'Multimedia2', 'Voice'"
	echo " Backend: 'HeadsetMic', 'OnboardMic', 'Aux/FM', 'DMic0', 'DMic1', 'DMic2'"
	echo " Port: 'm n',"
	echo " Format: 'S16_LE', 'S32_LE'"
	echo " Rate: 8000, 16000, 48000"
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

if [ "$AUDIOLIBRARY" = "ALSA" ]; then
	$TESTSCRIPT/OMAP4ConfigureInput.sh $frontend $backend Enable || exit 1
else
	$TESTSCRIPT/OMAP4TinyConfigureInput.sh $frontend $backend Enable || exit 1
fi

echo "Recording 5s..."

if [ "$AUDIOLIBRARY" = "ALSA" ]; then
	if [ "$buffer_time" = "" ]; then
		arecord -D $port -f $format -r $rate -c $channels -d 5 $TMPBASE/record.wav || exit 1
	else
		arecord -D $port -f $format -r $rate -c $channels -d 5 --buffer-time=$buffer_time $TMPBASE/record.wav || exit 1
	fi
else
	if [ "$buffer_time" = "" ]; then
		tinycap $TMPBASE/record.wav -d $port -r $rate  -f $format -c $channels -du 5
	else
		tinycap $TMPBASE/record.wav -d $port -r $rate  -f $format -c $channels -du 5 -ps $buffer_time
	fi
fi

if [ "$AUDIOLIBRARY" = "ALSA" ]; then
	$TESTSCRIPT/OMAP4ConfigureInput.sh $frontend $backend Disable || exit 1
else
	$TESTSCRIPT/OMAP4TinyConfigureInput.sh $frontend $backend Disable || exit 1
fi
echo "Done"


if [ "$AUDIOLIBRARY" = "ALSA" ]; then
	if [ "$frontend" = "Voice" ]; then
		$TESTSCRIPT/OMAP4ConfigureOutput.sh Voice Headset Enable || exit 1
		aplay -D plughw:0,2 $TMPBASE/record.wav || exit 1
		$TESTSCRIPT/OMAP4ConfigureOutput.sh Voice Headset Disable || exit 1
	else
		$TESTSCRIPT/OMAP4ConfigureOutput.sh Multimedia Headset Enable || exit 1
		aplay -D plughw:0,0 $TMPBASE/record.wav || exit 1
		$TESTSCRIPT/OMAP4ConfigureOutput.sh Multimedia Headset Disable || exit 1
	fi
else
	if [ "$frontend" = "Voice" ]; then
		$TESTSCRIPT/OMAP4TinyConfigureOutput.sh Voice Headset Enable || exit 1
		tinyplay  $TMPBASE/record.wav -d 2 -du 10
		$TESTSCRIPT/OMAP4TinyConfigureOutput.sh Voice Headset Disable || exit 1
	else
		$TESTSCRIPT/OMAP4TinyConfigureOutput.sh Multimedia Headset Enable || exit 1
		tinyplay  $TMPBASE/record.wav -d 0 -du 10
		$TESTSCRIPT/OMAP4TinyConfigureOutput.sh Multimedia Headset Disable || exit 1
	fi
fi
