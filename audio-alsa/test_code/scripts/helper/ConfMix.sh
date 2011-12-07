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
	tinymix $id "$val" | grep 'Error' && exit 1 || exit 0
}

if [ $# -lt 2 ]; then
	echo "Usage: $0 <cname> <value>"
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

WriteControl "$1" "$2"
