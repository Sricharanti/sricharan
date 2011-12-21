#!/bin/bash
#Initial cleanup
rm *.log

#Array containing the current OMAP4 SYSFS entries for HMC5843
SYSFS_DC_ENTRIES=(bias driver enable gain modalias mode name power rate subsystem uevent)
IFS=!
CURRENT_SYSFS_ENTRIES=(`ls $DIGITAL_COMPASS_SYSFS`)
#ARRAY=(`ls`)
COUNT=0

for i in ${CURRENT_SYSFS_ENTRIES[*]}
do
	printf "%s\n" $i
	printf "%s\n" $i >> current_sysfs.log
        let COUNT++;
done

for i in ${SYSFS_DC_ENTRIES[*]}
do 
	echo -e "Looking for Digital Compass SYSFS entries:\n"
        sleep 1
        printf "%s\n" $i
        printf "%s\n" $i >> debug.log

done

diff -purN current_sysfs.log debug.log

if [ $? -eq 0 ]
        then
                echo -e "--------------------------------------------"
                echo -e "PASS: SYSFS entries were found"
                echo -e "--------------------------------------------\n"
        else
                echo -e "++++++++++++++++++++++++++++++++++++"
                echo -e "FAIL: At least one SYSFS is missing"
                echo -e "++++++++++++++++++++++++++++++++++++\n"
fi
