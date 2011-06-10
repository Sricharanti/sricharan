#!/bin/sh

handlerError.sh "test"
if [ $? -eq 1 ]; then
	exit 1
fi

if [ $# -lt 1 ]; then
	echo "Usage: $0 <Direction>"
        echo " Direction: 'Capture', 'Playback'"
	exit 1
fi

direction=$1

if [ "$direction" = "Capture" ]; then
	frontends="Multimedia Multimedia2 Voice"
	backends="Headset Handsfree"
elif [ "$direction" = "Playback" ]; then
	frontends="Multimedia MultimediaLP Tones Voice"
	backends="Headset Handsfree Earpiece"
else
	echo "Invalid audio stream direction '$direction'"
	exit 1
fi

echo "*****************************************************************"
echo " Clear Audio $direction Paths  "
echo "*****************************************************************"

for frontend in $frontends; do
	for backend in $backends; do
		if [ "$direction" = "Capture" ]; then
			$TESTSCRIPT/OMAP4ConfigureInput.sh $frontend $backend Disable || exit 1
		else
			$TESTSCRIPT/OMAP4ConfigureOutput.sh $frontend $backend Disable || exit 1
		fi
	done
done
