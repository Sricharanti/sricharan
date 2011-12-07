#!/bin/sh

handlerError.sh "test"
if [ $? -eq 1 ]; then
	exit 1
fi

if [ $# -lt 6 ]; then
	echo "Usage: $0 <Frontend> <Backend> <Port> <Format> <Rate> <Channels>"
	echo " Frontend: 'Multimedia', 'MultimediaLP', 'Tones', 'Voice'"
	echo " Backend: 'Headset', 'Handsfree', 'Earpiece'"
	echo " Port: '0, 1, hw:0,0...'"
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
echo " Audio Playback "
echo " - Frontend: $frontend "
echo " - Backend: $backend "
echo " - Port: $port "
echo " - Configuration: Format:$format Rate:$rate Channels:$channels"
echo "*****************************************************************"

if [ "$AUDIOLIBRARY" = "ALSA" ]; then
	$TESTSCRIPT/OMAP4ConfigureOutput.sh $frontend $backend Enable || exit 1
else
	$TESTSCRIPT/OMAP4TinyConfigureOutput.sh $frontend $backend Enable || exit 1
fi


if [ "$AUDIOLIBRARY" = "ALSA" ]; then
	if [ "$buffer_time" = "" ]; then
		aplay -D $port -d 10 $SAMPLESDIR/Sample-"$format"-"$rate"-"$channels".wav || exit 1
	else
		aplay -D $port -d 10 --buffer-time=$buffer_time $SAMPLESDIR/Sample-"$format"-"$rate"-"$channels".wav || exit 1
	fi
else
	if [ "$buffer_time" = "" ]; then
		tinyplay $SAMPLESDIR/Sample-"$format"-"$rate"-"$channels".wav -d $port -du 10 || exit 1
	else
		tinyplay $SAMPLESDIR/Sample-"$format"-"$rate"-"$channels".wav -d $port -du 10 -ps $buffer_time || exit 1
	fi
fi

if [ "$AUDIOLIBRARY" = "ALSA" ]; then
	$TESTSCRIPT/OMAP4ConfigureOutput.sh $frontend $backend Disable || exit 1
else
	$TESTSCRIPT/OMAP4TinyConfigureOutput.sh $frontend $backend Disable || exit 1
fi
