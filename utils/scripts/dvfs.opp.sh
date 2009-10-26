#!/bin/sh

MAXCOUNT=99999
count=3

echo 1 > /sys/power/sr_vdd1_autocomp
echo 1 > /sys/power/sr_vdd2_autocomp

while [ "$count" -le $MAXCOUNT ]
do
	vdd1_opp_no=`expr $count % 5`
	vdd1_opp_no=`expr $vdd1_opp_no + 1`
	echo -n $vdd1_opp_no > /sys/power/vdd1_opp
	#echo VDD1:
	#cat /sys/power/vdd1_opp
	sleep 1
	vdd2_opp_no=`expr $count % 2`
	vdd2_opp_no=`expr $vdd2_opp_no + 2`
	echo -n $vdd2_opp_no > /sys/power/vdd2_opp
	#echo VDD2:
	#cat /sys/power/vdd2_opp
	sleep 1
	count=`expr $count + 1`
done
