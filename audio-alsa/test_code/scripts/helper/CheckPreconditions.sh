#!/bin/sh

if [ $# -lt 1 ]; then
	echo "Usage: $0 <Samples Directory>"
	exit 1
fi

samplesdir=$1
formats="S16_LE S24_LE S32_LE"
rates="8000 11025 12000 16000 22050 24000 32000 44100 48000 64000 88200 96000"
channels="1 2"

printMissingSamples() {
	echo " FATAL: Sample files missing: "
        while read line
        do
		echo "- $line"
        done < $TMPBASE/missing_samples.log
	echo ""
	rm -v $TMPBASE/missing_samples.log
	handlerError.sh "log" "1" "halt" "CheckPreconditions.sh"
	exit 1
}

# Check for alsa-utils
if ! ([ -f "/bin/aplay" ] || [ -f "/usr/bin/aplay" ]); then
	echo " FATAL: alsa-utils not found (aplay)"
	handlerError.sh "log" "1" "halt" "CheckPreconditions.sh"
	exit 1
fi

if ! ([ -f "/bin/arecord" ] || [ -f "/usr/bin/arecord" ]); then
	echo " FATAL: alsa-utils not found (arecord)"
	handlerError.sh "log" "1" "halt" "CheckPreconditions.sh"
	exit 1
fi

if ! ([ -f "/bin/amixer" ] || [ -f "/usr/bin/amixer" ]); then
	echo " FATAL: alsa-utils not found (amixer)"
	handlerError.sh "log" "1" "halt" "CheckPreconditions.sh"
	exit 1
fi

# Check for sample files
if [ -f $TMPBASE/missing_samples.log ]; then
	rm -v $TMPBASE/missing_samples.log
fi

for format in $formats; do
	for rate in $rates; do
		for channel in $channels; do
			filename="Sample-$format-$rate-$channel.wav"
			test -f $samplesdir/$filename || echo $filename >> $TMPBASE/missing_samples.log
		done
	done
done

# Additional samples
filenames="Sample-S16_LE-7000-2.wav Sample-S16_LE-48000-2-Long.wav Sample-S16_LE-48000-2-L.wav Sample-S16_LE-48000-2-R.wav Sample-S32_LE-192000-2.wav"
for filename in $filenames; do
	test -f $samplesdir/$filename || echo $filename >> $TMPBASE/missing_samples.log
done

if [ -f $TMPBASE/missing_samples.log ]; then
	printMissingSamples
fi
