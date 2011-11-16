#!/bin/sh


mmcfile=`ls /sys/class/mmc_host/mmc${SLOT}/ | grep "mmc${SLOT}:*"`
mmcsdtype=`cat /sys/class/mmc_host/mmc${SLOT}/$mmcfile/type`
echo "mmcsdtype = $mmcsdtype"

if [ $mmcsdtype == "SD" ]; then
        hctl=`cat /d/mmc${SLOT}/regs | grep HCTL`
        echo "hctl= $hctl"
        regvalue=`echo $hctl | cut -d' ' -f2`
        echo "regvalue=$regvalue"
        nibble=`expr substr $regvalue 10 1`
        echo "nibble = $nibble"
        if [ `expr $nibble = 2` ]; then
                echo "Success: 4 bit mode"
                exit 0
        else
                echo "Fail"
                exit 1
        fi

elif [ $mmcsdtype == "MMC" ]; then
        echo "Yet to be implemented!#!/bin/sh


mmcfile=`ls /sys/class/mmc_host/mmc${SLOT}/ | grep "mmc${SLOT}:*"`
mmcsdtype=`cat /sys/class/mmc_host/mmc${SLOT}/$mmcfile/type`
echo "mmcsdtype = $mmcsdtype"

if [ $mmcsdtype == "SD" ]; then
        hctl=`cat /d/mmc${SLOT}/regs | grep HCTL`
        echo "hctl= $hctl"
        regvalue=`echo $hctl | cut -d' ' -f2`
        echo "regvalue=$regvalue"
        nibble=`expr substr $regvalue 10 1`
        echo "nibble = $nibble"
        if [ `expr $nibble = 2` ]; then
                echo "Success: 4 bit mode"
                exit 0
        else
                echo "Fail"
                exit 1
        fi

elif [ $mmcsdtype == "MMC" ]; then
        echo "Need to do something else here"
        exit 1
fi
"
        exit 1
fi

