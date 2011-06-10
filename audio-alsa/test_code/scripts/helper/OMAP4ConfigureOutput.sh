#!/bin/sh

if [ $# -lt 3 ]; then
	echo "Usage: $0 <Frontend> <Backend> <Enable/Disable>"
	echo " Frontend: 'Multimedia', 'Voice', 'Tones', 'MultimediaLP'"
	echo " Backend: 'Headset', 'Handsfree', 'Earpiece'"
	exit 1
fi

frontend=$1
backend=$2
enable=$3

echo "Configuring frontend '$frontend' -> backend '$backend': $enable"

# Frontend dependent components
if [ "$frontend" == "Multimedia" ] || [ "$frontend" == "MultimediaLP" ]; then
	if [ "$backend" == "Headset" ] ||
	   [ "$backend" == "Earpiece" ] ; then
		if [ "$enable" == "Enable" ]; then
			amixer cset name='DL1 Mixer Multimedia' 1
			amixer cset name='DL1 Media Playback Volume' 118
		else
			amixer cset name='DL1 Mixer Multimedia' 0
			amixer cset name='DL1 Media Playback Volume' 0
		fi
	elif [ "$backend" == "Handsfree" ]; then
		if [ "$enable" == "Enable" ]; then
			amixer cset name='DL2 Mixer Multimedia' 1
			amixer cset name='DL2 Media Playback Volume' 118
		else
			amixer cset name='DL2 Mixer Multimedia' 0
			amixer cset name='DL2 Media Playback Volume' 0
		fi
	else
		echo "Backend '$backend' not supported with frontend '$frontend'"
		exit 1
	fi
elif [ "$frontend" == "Voice" ]; then
	if [ "$backend" == "Headset" ] ||
	   [ "$backend" == "Earpiece" ] ; then
		if [ "$enable" == "Enable" ]; then
			amixer cset name='DL1 Mixer Voice' 1
			amixer cset name='DL1 Voice Playback Volume' 118
		else
			amixer cset name='DL1 Mixer Voice' 0
			amixer cset name='DL1 Voice Playback Volume' 0
		fi
	elif [ "$backend" == "Handsfree" ]; then
		if [ "$enable" == "Enable" ]; then
			amixer cset name='DL2 Mixer Voice' 1
			amixer cset name='DL2 Voice Playback Volume' 118
		else
			amixer cset name='DL2 Mixer Voice' 0
			amixer cset name='DL2 Voice Playback Volume' 0
		fi
	else
		echo "Backend '$backend' not supported with frontend '$frontend'"
		exit 1
	fi
elif [ "$frontend" == "Tones" ]; then
	if [ "$backend" == "Headset" ] ||
	   [ "$backend" == "Earpiece" ] ; then
		if [ "$enable" == "Enable" ]; then
			amixer cset name='DL1 Mixer Tones' 1
			amixer cset name='DL1 Tones Playback Volume' 118
		else
			amixer cset name='DL1 Mixer Tones' 0
			amixer cset name='DL1 Tones Playback Volume' 0
		fi
	elif [ "$backend" == "Handsfree" ]; then
		if [ "$enable" == "Enable" ]; then
			amixer cset name='DL2 Mixer Tones' 1
			amixer cset name='DL2 Tones Playback Volume' 118
		else
			amixer cset name='DL2 Mixer Tones' 0
			amixer cset name='DL2 Tones Playback Volume' 0
		fi
	else
		echo "Backend '$backend' not supported with frontend '$frontend'"
		exit 1
	fi
else
	echo "Frontend $frontend is not supported"
	exit 1
fi

# Backend dependent controls
if [ "$backend" == "Headset" ]; then
	if [ "$enable" == "Enable" ]; then
		amixer cset name='Sidetone Mixer Playback' 1
		amixer cset name='SDT DL Volume' 120
		amixer cset name='DL1 PDM Switch' 1
		amixer cset name='HS Left Playback' 'HS DAC'
		amixer cset name='HS Right Playback' 'HS DAC'
		amixer cset name='Headset Playback Volume' 13
	else
		amixer cset name='Sidetone Mixer Playback' 0
		amixer cset name='SDT DL Volume' 0
		amixer cset name='DL1 PDM Switch' 0
		amixer cset name='HS Left Playback' 'Off'
		amixer cset name='HS Right Playback' 'Off'
		amixer cset name='Headset Playback Volume' 0
	fi
elif [ "$backend" == "Handsfree" ]; then
	if [ "$enable" == "Enable" ]; then
		amixer cset name='HF Left Playback' 'HF DAC'
		amixer cset name='HF Right Playback' 'HF DAC'
		amixer cset name='Handsfree Playback Volume' 15
	else
		amixer cset name='HF Left Playback' 'Off'
		amixer cset name='HF Right Playback' 'Off'
		amixer cset name='Handsfree Playback Volume' 0
	fi
elif [ "$backend" == "Earpiece" ]; then
	if [ "$enable" == "Enable" ]; then
		amixer cset name='Sidetone Mixer Playback' 1
		amixer cset name='SDT DL Volume' 120
		amixer cset name='DL1 PDM Switch' 1
		amixer cset name='Earphone Driver Switch' 1
		amixer cset name='Earphone Playback Volume' 13
	else
		amixer cset name='Sidetone Mixer Playback' 0
		amixer cset name='SDT DL Volume' 0
		amixer cset name='DL1 PDM Switch' 0
		amixer cset name='Earphone Driver Switch' 0
		amixer cset name='Earphone Playback Volume' 0
	fi
else
	echo "Backend '$backend' is not supported"
	exit 1
fi

echo "Done"
