#!/bin/sh

if [ $# -lt 3 ]; then
	echo "Usage: $0 <Frontend> <Backend> <Enable/Disable>"
	echo " Frontend: 'Multimedia', 'Multimedia2', 'Voice'"
	echo " Backend: 'HeadsetMic', 'OnboardMic', 'Aux/FM', 'DMic0', 'DMic1', 'DMic2'"
	exit 1
fi

frontend=$1
backend=$2
enable=$3

echo "Configuring frontend '$frontend' -> backend '$backend': $enable"

# Frontend dependent components
if [ "$frontend" == "Multimedia" ]; then
	if [ "$enable" == "Enable" ]; then
		if [ "$backend" == "HeadsetMic" ] ||
		   [ "$backend" == "OnboardMic" ] ||
		   [ "$backend" == "Aux/FM" ]; then
			amixer cset name='MUX_UL00' 'AMic0'
			amixer cset name='MUX_UL01' 'AMic1'
			amixer cset name='AMIC_UL PDM Switch' 1
			amixer cset name='AMIC UL Volume' 120
		elif [ "$backend" == "DMic0" ]; then
			amixer cset name='MUX_UL00' 'DMic0L'
			amixer cset name='MUX_UL01' 'DMic0R'
			amixer cset name='DMIC1 UL Volume' 140
		elif [ "$backend" == "DMic1" ]; then
			amixer cset name='MUX_UL00' 'DMic1L'
			amixer cset name='MUX_UL01' 'DMic1R'
			amixer cset name='DMIC2 UL Volume' 140
		elif [ "$backend" == "DMic2" ]; then
			amixer cset name='MUX_UL00' 'DMic2L'
			amixer cset name='MUX_UL01' 'DMic2R'
			amixer cset name='DMIC3 UL Volume' 140
		else
			echo "Backend '$backend' not supported with frontend '$frontend'"
			exit 1
		fi
	else
		if [ "$backend" == "HeadsetMic" ] ||
		   [ "$backend" == "OnboardMic" ] ||
		   [ "$backend" == "Aux/FM" ]; then
			amixer cset name='AMIC_UL PDM Switch' 0
			amixer cset name='AMIC UL Volume' 0
		elif [ "$backend" == "DMic0" ]; then
			amixer cset name='DMIC1 UL Volume' 0
		elif [ "$backend" == "DMic1" ]; then
			amixer cset name='DMIC2 UL Volume' 0
		elif [ "$backend" == "DMic2" ]; then
			amixer cset name='DMIC3 UL Volume' 0
		fi
		amixer cset name='MUX_UL00' 'None'
		amixer cset name='MUX_UL01' 'None'
	fi
elif [ "$frontend" == "Multimedia2" ]; then
	if [ "$enable" == "Enable" ]; then
		if [ "$backend" == "HeadsetMic" ] ||
		   [ "$backend" == "OnboardMic" ] ||
		   [ "$backend" == "Aux/FM" ]; then
			amixer cset name='MUX_UL10' 'AMic0'
			amixer cset name='MUX_UL11' 'AMic1'
			amixer cset name='AMIC_UL PDM Switch' 1
			amixer cset name='AMIC UL Volume' 120
		elif [ "$backend" == "DMic0" ]; then
			amixer cset name='MUX_UL10' 'DMic0L'
			amixer cset name='MUX_UL11' 'DMic0R'
			amixer cset name='DMIC1 UL Volume' 140
		elif [ "$backend" == "DMic1" ]; then
			amixer cset name='MUX_UL10' 'DMic1L'
			amixer cset name='MUX_UL11' 'DMic1R'
			amixer cset name='DMIC2 UL Volume' 140
		elif [ "$backend" == "DMic2" ]; then
			amixer cset name='MUX_UL10' 'DMic2L'
			amixer cset name='MUX_UL11' 'DMic2R'
			amixer cset name='DMIC3 UL Volume' 140
		else
			echo "Backend '$backend' not supported with frontend '$frontend'"
			exit 1
		fi
	else
		if [ "$backend" == "HeadsetMic" ] ||
		   [ "$backend" == "OnboardMic" ] ||
		   [ "$backend" == "Aux/FM" ]; then
			amixer cset name='AMIC_UL PDM Switch' 0
			amixer cset name='AMIC UL Volume' 0
		elif [ "$backend" == "DMic0" ]; then
			amixer cset name='DMIC1 UL Volume' 0
		elif [ "$backend" == "DMic1" ]; then
			amixer cset name='DMIC2 UL Volume' 0
		elif [ "$backend" == "DMic2" ]; then
			amixer cset name='DMIC3 UL Volume' 0
		fi
		amixer cset name='MUX_UL10' 'None'
		amixer cset name='MUX_UL11' 'None'
	fi
elif [ "$frontend" == "Voice" ]; then
	if [ "$enable" == "Enable" ]; then
		if [ "$backend" == "HeadsetMic" ] ||
		   [ "$backend" == "OnboardMic" ] ||
		   [ "$backend" == "Aux/FM" ]; then
			amixer cset name='MUX_VX0' 'AMic0'
			amixer cset name='MUX_VX1' 'AMic1'
			amixer cset name='AMIC_UL PDM Switch' 1
			amixer cset name='AMIC UL Volume' 120
		elif [ "$backend" == "DMic0" ]; then
			amixer cset name='MUX_VX0' 'DMic0L'
			amixer cset name='MUX_VX1' 'DMic0R'
			amixer cset name='DMIC1 UL Volume' 140
		elif [ "$backend" == "DMic1" ]; then
			amixer cset name='MUX_VX0' 'DMic1L'
			amixer cset name='MUX_VX1' 'DMic1R'
			amixer cset name='DMIC2 UL Volume' 140
		elif [ "$backend" == "DMic2" ]; then
			amixer cset name='MUX_VX0' 'DMic2L'
			amixer cset name='MUX_VX1' 'DMic2R'
			amixer cset name='DMIC3 UL Volume' 140
		else
			echo "Backend '$backend' not supported with frontend '$frontend'"
			exit 1
		fi
		amixer cset name='Voice Capture Mixer Capture' 1
		amixer cset name='AUDUL Voice UL Volume' 120
	else
		if [ "$backend" == "HeadsetMic" ] ||
		   [ "$backend" == "OnboardMic" ] ||
		   [ "$backend" == "Aux/FM" ]; then
			amixer cset name='AMIC_UL PDM Switch' 0
			amixer cset name='AMIC UL Volume' 0
		elif [ "$backend" == "DMic0" ]; then
			amixer cset name='DMIC1 UL Volume' 0
		elif [ "$backend" == "DMic1" ]; then
			amixer cset name='DMIC2 UL Volume' 0
		elif [ "$backend" == "DMic2" ]; then
			amixer cset name='DMIC3 UL Volume' 0
		fi
		amixer cset name='MUX_VX0' 'None'
		amixer cset name='MUX_VX1' 'None'
		amixer cset name='Voice Capture Mixer Capture' 0
		amixer cset name='AUDUL Voice UL Volume' 0
	fi
else
	echo "Frontend '$frontend' is not supported"
	exit 1
fi

# Backend dependent controls
if [ "$backend" == "HeadsetMic" ]; then
	if [ "$enable" == "Enable" ]; then
		amixer cset name='Analog Left Capture Route' 'Headset Mic'
		amixer cset name='Analog Right Capture Route' 'Headset Mic'
		amixer cset name='Capture Preamplifier Volume' 1
		amixer cset name='Capture Volume' 4
	else
		amixer cset name='Analog Left Capture Route' 'Off'
		amixer cset name='Analog Right Capture Route' 'Off'
		amixer cset name='Capture Preamplifier Volume' 0
		amixer cset name='Capture Volume' 0
	fi
elif [ "$backend" == "OnboardMic" ]; then
	if [ "$enable" == "Enable" ]; then
		amixer cset name='Analog Left Capture Route' 'Main Mic'
		amixer cset name='Analog Right Capture Route' 'Sub Mic'
		amixer cset name='Capture Preamplifier Volume' 1
		amixer cset name='Capture Volume' 4
	else
		amixer cset name='Analog Left Capture Route' 'Off'
		amixer cset name='Analog Right Capture Route' 'Off'
		amixer cset name='Capture Preamplifier Volume' 0
		amixer cset name='Capture Volume' 0
	fi
elif [ "$backend" == "Aux/FM" ]; then
	if [ "$enable" == "Enable" ]; then
		amixer cset name='Analog Left Capture Route' 'Aux/FM Left'
		amixer cset name='Analog Right Capture Route' 'Aux/FM Right'
		amixer cset name='Capture Preamplifier Volume' 1
		amixer cset name='Capture Volume' 4
	else
		amixer cset name='Analog Left Capture Route' 'Off'
		amixer cset name='Analog Right Capture Route' 'Off'
		amixer cset name='Capture Preamplifier Volume' 0
		amixer cset name='Capture Volume' 0
	fi
fi

echo "Done"
