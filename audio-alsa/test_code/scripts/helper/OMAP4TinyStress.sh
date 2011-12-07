#!/bin/sh

frontend=$1
backend=$2
port=$3
filename=$4
iterations=$5

$TESTSCRIPT/OMAP4TinyConfigureOutput.sh $frontend $backend Enable || exit 1
for i in `seq $iterations`
do
	echo $i
		tinyplay $filename -d $port -du 10  || exit 1
done
$TESTSCRIPT/OMAP4TinyConfigureOutput.sh $frontend $backend Disable || exit 1
