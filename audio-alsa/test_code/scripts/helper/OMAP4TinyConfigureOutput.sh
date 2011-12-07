#!/bin/bash

function WriteControl {
	control=$1
	val=$2

	id=`awk '/'"$control"'/{print $1}' controls.txt`
	if [ "$id" != "" ]; then
		echo "  \"$control\": $val"
	else
		echo "* \"$control\": not found!"
		exit 1
	fi
	tinymix $id "$val" | grep 'Error' && exit 1 || return 0
}

if [ $# -lt 3 ]; then
	echo "Usage: $0 <Frontend> <Backend> <Enable/Disable>"
	echo "Frontends: 'Multimedia', 'Voice', 'Tones', 'MultimediaLP'"
	echo "Backends: 'Headset', 'Handsfree', 'Bluetooth'"
	exit 1
fi

frontend=$1
backend=$2
enable=$3

tinymix > controls.txt

if ! [ -s controls.txt ]; then
	echo "Couldn't retrieve controls from device"
	exit 1
fi

echo "Configuring frontend '$frontend' -> backend '$backend': $enable"

# Frontend dependent components
if [ "$frontend" == "Multimedia" ] || [ "$frontend" == "MultimediaLP" ]; then
	if [ "$backend" == "Headset" ]; then
		if [ "$enable" == "Enable" ]; then
			WriteControl 'DL1 Mixer Multimedia' 1
			WriteControl 'DL1 Media Playback Volume' 118
		else
			WriteControl 'DL1 Mixer Multimedia' 0
			WriteControl 'DL1 Media Playback Volume' 0
		fi
	elif [ "$backend" == "Handsfree" ]; then
		if [ "$enable" == "Enable" ]; then
			WriteControl 'DL2 Mixer Multimedia' 1
			WriteControl 'DL2 Media Playback Volume' 118
		else
			WriteControl 'DL2 Mixer Multimedia' 0
			WriteControl 'DL2 Media Playback Volume' 0
		fi
	else
		echo "Backend '$backend' not supported with frontend '$frontend'"
		exit 1
	fi
elif [ "$frontend" == "Voice" ]; then
	if [ "$backend" == "Headset" ]  || [ "$backend" == "Bluetooth" ]; then
		if [ "$enable" == "Enable" ]; then
			WriteControl 'DL1 Mixer Voice' 1
			WriteControl 'DL1 Voice Playback Volume' 118
		else
			WriteControl 'DL1 Mixer Voice' 0
			WriteControl 'DL1 Voice Playback Volume' 0
		fi
	elif [ "$backend" == "Handsfree" ]; then
		if [ "$enable" == "Enable" ]; then
			WriteControl 'DL2 Mixer Voice' 1
			WriteControl 'DL2 Voice Playback Volume' 118
		else
			WriteControl 'DL2 Mixer Voice' 0
			WriteControl 'DL2 Voice Playback Volume' 0
		fi
	else
		echo "Backend '$backend' not supported with frontend '$frontend'"
		exit 1
	fi
elif [ "$frontend" == "Tones" ]; then
	if [ "$backend" == "Headset" ]  || [ "$backend" == "Bluetooth" ]; then
		if [ "$enable" == "Enable" ]; then
			WriteControl 'DL1 Mixer Tones' 1
			WriteControl 'DL1 Tones Playback Volume' 118
		else
			WriteControl 'DL1 Mixer Tones' 0
			WriteControl 'DL1 Tones Playback Volume' 0
		fi
	elif [ "$backend" == "Handsfree" ]; then
		if [ "$enable" == "Enable" ]; then
			WriteControl 'DL2 Mixer Tones' 1
			WriteControl 'DL2 Tones Playback Volume' 118
		else
			WriteControl 'DL2 Mixer Tones' 0
			WriteControl 'DL2 Tones Playback Volume' 0
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
		WriteControl 'Sidetone Mixer Playback' 1
		WriteControl 'SDT DL Volume' 120
		WriteControl 'DL1 PDM Switch' 1
		WriteControl 'HS Left Playback' 'HS DAC'
		WriteControl 'HS Right Playback' 'HS DAC'
		WriteControl 'Headset Playback Volume' 13
	else
		WriteControl 'Sidetone Mixer Playback' 0
		WriteControl 'SDT DL Volume' 0
		WriteControl 'DL1 PDM Switch' 0
		WriteControl 'HS Left Playback' 'Off'
		WriteControl 'HS Right Playback' 'Off'
		WriteControl 'Headset Playback Volume' 0
	fi
elif [ "$backend" == "Bluetooth" ]; then
	if [ "$enable" == "Enable" ]; then
		WriteControl 'Sidetone Mixer Playback' 1
		WriteControl 'SDT DL Volume' 120
		WriteControl 'DL1 BT_VX Switch' 1
		WriteControl 'BT UL Volume' 120
	else
		WriteControl 'Sidetone Mixer Playback' 0
		WriteControl 'SDT DL Volume' 0
		WriteControl 'DL1 BT_VX Switch' 1
		WriteControl 'BT UL Volume' 0
	fi
elif [ "$backend" == "Handsfree" ]; then
	if [ "$enable" == "Enable" ]; then
		WriteControl 'HF Left Playback' 'HF DAC'
		WriteControl 'HF Right Playback' 'HF DAC'
		WriteControl 'Handsfree Playback Volume' 23
	else
		WriteControl 'HF Left Playback' 'Off'
		WriteControl 'HF Right Playback' 'Off'
		WriteControl 'Handsfree Playback Volume' 0
	fi
else
	echo "Backend '$backend' is not supported"
	exit 1
fi
