#!/bin/sh

if [ $# -lt 1 ]; then
	echo "Usage: $0 <Samples Directory>"
	exit 1
fi

samplesdir=$1
formats="S16_LE S24_LE S32_LE"
rates="8000 11025 12000 16000 22050 24000 32000 44100 48000 64000 88200 96000"
channels="1 2"

if [ "$AUDIOLIBRARY" = "ALSA" ]; then
	playback="aplay"
	capture="arecord"
	mixer="amixer"
else
	playback="tinyplay"
	capture="tinycap"
	mixer="tinymix"
fi

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
if ! ([ -f "/bin/$playback" ] || [ -f "/system/bin/$playback" ]); then
	echo " FATAL: utils not found ($playback)"
	handlerError.sh "log" "1" "halt" "CheckPreconditions.sh"
	exit 1
fi

if ! ([ -f "/bin/$capture" ] || [ -f "/system/bin/$capture" ]); then
	echo " FATAL: utils not found ($capture)"
	handlerError.sh "log" "1" "halt" "CheckPreconditions.sh"
	exit 1
fi

if ! ([ -f "/bin/$mixer" ] || [ -f "/system/bin/$mixer" ]); then
	echo " FATAL: utils not found ($mixer)"
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
echo $TMPBASE

# Additional samples
filenames="Sample-S16_LE-7000-2.wav Sample-S16_LE-48000-2-Long.wav Sample-S16_LE-48000-2-L.wav Sample-S16_LE-48000-2-R.wav Sample-S32_LE-192000-2.wav"
for filename in $filenames; do
	test -f $samplesdir/$filename || echo $filename >> $TMPBASE/missing_samples.log
done

if [ -f $TMPBASE/missing_samples.log ]; then
	printMissingSamples
fi
