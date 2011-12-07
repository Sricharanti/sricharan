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
	echo "Frontends: 'Multimedia', 'Multimedia2', 'Voice'"
	echo "Backends: 'HeadsetMic', 'OnboardMic', 'Aux/FM', 'DMic0', 'DMic1', 'DMic2'"
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
if [ "$frontend" == "Multimedia" ]; then
	if [ "$enable" == "Enable" ]; then
		if [ "$backend" == "HeadsetMic" ] ||
		   [ "$backend" == "OnboardMic" ] ||
		   [ "$backend" == "Aux/FM" ]; then
			WriteControl 'MUX_UL00' 'AMic0'
			WriteControl 'MUX_UL01' 'AMic1'
			WriteControl 'MUX_UL02' 'None'
			WriteControl 'MUX_UL03' 'None'
			WriteControl 'MUX_UL04' 'None'
			WriteControl 'MUX_UL05' 'None'
			WriteControl 'MUX_UL06' 'None'
			WriteControl 'MUX_UL07' 'None'
		elif [ "$backend" == "DMic0" ]; then
			WriteControl 'MUX_UL00' 'DMic0L'
			WriteControl 'MUX_UL01' 'DMic0R'
			WriteControl 'MUX_UL02' 'None'
			WriteControl 'MUX_UL03' 'None'
			WriteControl 'MUX_UL04' 'None'
			WriteControl 'MUX_UL05' 'None'
			WriteControl 'MUX_UL06' 'None'
			WriteControl 'MUX_UL07' 'None'
			WriteControl 'DMIC1 UL Volume' 140
		elif [ "$backend" == "DMic1" ]; then
			WriteControl 'MUX_UL00' 'DMic1L'
			WriteControl 'MUX_UL01' 'DMic1R'
			WriteControl 'MUX_UL02' 'None'
			WriteControl 'MUX_UL03' 'None'
			WriteControl 'MUX_UL04' 'None'
			WriteControl 'MUX_UL05' 'None'
			WriteControl 'MUX_UL06' 'None'
			WriteControl 'MUX_UL07' 'None'
			WriteControl 'DMIC2 UL Volume' 140
		elif [ "$backend" == "DMic2" ]; then
			WriteControl 'MUX_UL00' 'DMic2L'
			WriteControl 'MUX_UL01' 'DMic2R'
			WriteControl 'MUX_UL02' 'None'
			WriteControl 'MUX_UL03' 'None'
			WriteControl 'MUX_UL04' 'None'
			WriteControl 'MUX_UL05' 'None'
			WriteControl 'MUX_UL06' 'None'
			WriteControl 'MUX_UL07' 'None'
			WriteControl 'DMIC3 UL Volume' 140
		elif [ "$backend" == "Bluetooth" ]; then
			WriteControl 'MUX_UL00' 'BT Left'
			WriteControl 'MUX_UL01' 'BT Right'
			WriteControl 'MUX_UL02' 'None'
			WriteControl 'MUX_UL03' 'None'
			WriteControl 'MUX_UL04' 'None'
			WriteControl 'MUX_UL05' 'None'
			WriteControl 'MUX_UL06' 'None'
			WriteControl 'MUX_UL07' 'None'
		else
			echo "Backend '$backend' not supported with frontend '$frontend'"
			exit 1
		fi
	else
		if [ "$backend" == "DMic0" ]; then
			WriteControl 'DMIC1 UL Volume' 0
		elif [ "$backend" == "DMic1" ]; then
			WriteControl 'DMIC2 UL Volume' 0
		elif [ "$backend" == "DMic2" ]; then
			WriteControl 'DMIC3 UL Volume' 0
		fi
		WriteControl 'MUX_UL00' 'None'
		WriteControl 'MUX_UL01' 'None'
		WriteControl 'MUX_UL02' 'None'
		WriteControl 'MUX_UL03' 'None'
		WriteControl 'MUX_UL04' 'None'
		WriteControl 'MUX_UL05' 'None'
		WriteControl 'MUX_UL06' 'None'
		WriteControl 'MUX_UL07' 'None'
	fi
elif [ "$frontend" == "Multimedia2" ]; then
	if [ "$enable" == "Enable" ]; then
		if [ "$backend" == "HeadsetMic" ] ||
		   [ "$backend" == "OnboardMic" ] ||
		   [ "$backend" == "Aux/FM" ]; then
			WriteControl 'MUX_UL10' 'AMic0'
			WriteControl 'MUX_UL11' 'AMic1'
		elif [ "$backend" == "DMic0" ]; then
			WriteControl 'MUX_UL10' 'DMic0L'
			WriteControl 'MUX_UL11' 'DMic0R'
			WriteControl 'DMIC1 UL Volume' 140
		elif [ "$backend" == "DMic1" ]; then
			WriteControl 'MUX_UL10' 'DMic1L'
			WriteControl 'MUX_UL11' 'DMic1R'
			WriteControl 'DMIC2 UL Volume' 140
		elif [ "$backend" == "DMic2" ]; then
			WriteControl 'MUX_UL10' 'DMic2L'
			WriteControl 'MUX_UL11' 'DMic2R'
			WriteControl 'DMIC3 UL Volume' 140
		elif [ "$backend" == "Bluetooth" ]; then
			WriteControl 'MUX_UL10' 'BT Left'
			WriteControl 'MUX_UL11' 'BT Right'
		else
			echo "Backend '$backend' not supported with frontend '$frontend'"
			exit 1
		fi
	else
		if [ "$backend" == "DMic0" ]; then
			WriteControl 'DMIC1 UL Volume' 0
		elif [ "$backend" == "DMic1" ]; then
			WriteControl 'DMIC2 UL Volume' 0
		elif [ "$backend" == "DMic2" ]; then
			WriteControl 'DMIC3 UL Volume' 0
		fi
		WriteControl 'MUX_UL10' 'None'
		WriteControl 'MUX_UL11' 'None'
	fi
elif [ "$frontend" == "Voice" ]; then
	if [ "$enable" == "Enable" ]; then
		if [ "$backend" == "HeadsetMic" ] ||
		   [ "$backend" == "OnboardMic" ] ||
		   [ "$backend" == "Aux/FM" ]; then
			WriteControl 'MUX_VX0' 'AMic0'
			WriteControl 'MUX_VX1' 'AMic1'
		elif [ "$backend" == "DMic0" ]; then
			WriteControl 'MUX_VX0' 'DMic0L'
			WriteControl 'MUX_VX1' 'DMic0R'
			WriteControl 'DMIC1 UL Volume' 140
		elif [ "$backend" == "DMic1" ]; then
			WriteControl 'MUX_VX0' 'DMic1L'
			WriteControl 'MUX_VX1' 'DMic1R'
			WriteControl 'DMIC2 UL Volume' 140
		elif [ "$backend" == "DMic2" ]; then
			WriteControl 'MUX_VX0' 'DMic2L'
			WriteControl 'MUX_VX1' 'DMic2R'
			WriteControl 'DMIC3 UL Volume' 140
		elif [ "$backend" == "Bluetooth" ]; then
			WriteControl 'MUX_VX0' 'BT Left'
			WriteControl 'MUX_VX1' 'BT Right'
		else
			echo "Backend '$backend' not supported with frontend '$frontend'"
			exit 1
		fi
		WriteControl 'Voice Capture Mixer Capture' 1
		WriteControl 'AUDUL Voice UL Volume' 120
	else
		if [ "$backend" == "DMic0" ]; then
			WriteControl 'DMIC1 UL Volume' 0
		elif [ "$backend" == "DMic1" ]; then
			WriteControl 'DMIC2 UL Volume' 0
		elif [ "$backend" == "DMic2" ]; then
			WriteControl 'DMIC3 UL Volume' 0
		fi
		WriteControl 'MUX_VX0' 'None'
		WriteControl 'MUX_VX1' 'None'
		WriteControl 'Voice Capture Mixer Capture' 0
		WriteControl 'AUDUL Voice UL Volume' 0
	fi
else
	echo "Frontend '$frontend' is not supported"
	exit 1
fi

# Backend dependent controls
if [ "$backend" == "HeadsetMic" ]; then
	if [ "$enable" == "Enable" ]; then
		WriteControl 'AMIC UL Volume' 120
		WriteControl 'Analog Left Capture Route' 'Headset Mic'
		WriteControl 'Analog Right Capture Route' 'Headset Mic'
		WriteControl 'Capture Preamplifier Volume' 1
		WriteControl 'Capture Volume' 4
	else
		WriteControl 'AMIC UL Volume' 0
		WriteControl 'Analog Left Capture Route' 'Off'
		WriteControl 'Analog Right Capture Route' 'Off'
		WriteControl 'Capture Preamplifier Volume' 0
		WriteControl 'Capture Volume' 0
	fi
elif [ "$backend" == "OnboardMic" ]; then
	if [ "$enable" == "Enable" ]; then
		WriteControl 'AMIC UL Volume' 140
		WriteControl 'Analog Left Capture Route' 'Main Mic'
		WriteControl 'Analog Right Capture Route' 'Sub Mic'
		WriteControl 'Capture Preamplifier Volume' 1
		WriteControl 'Capture Volume' 4
	else
		WriteControl 'AMIC UL Volume' 0
		WriteControl 'Analog Left Capture Route' 'Off'
		WriteControl 'Analog Right Capture Route' 'Off'
		WriteControl 'Capture Preamplifier Volume' 0
		WriteControl 'Capture Volume' 0
	fi
elif [ "$backend" == "Aux/FM" ]; then
	if [ "$enable" == "Enable" ]; then
		WriteControl 'AMIC UL Volume' 120
		WriteControl 'Analog Left Capture Route' 'Aux/FM Left'
		WriteControl 'Analog Right Capture Route' 'Aux/FM Right'
		WriteControl 'Capture Preamplifier Volume' 1
		WriteControl 'Capture Volume' 4
	else
		WriteControl 'AMIC UL Volume' 0
		WriteControl 'Analog Left Capture Route' 'Off'
		WriteControl 'Analog Right Capture Route' 'Off'
		WriteControl 'Capture Preamplifier Volume' 0
	fi
fi
