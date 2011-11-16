#!/bin/sh

DURATION=3600

#TMPFILE=`mktemp /var/tmpXXXXXX`
NOWTIME=`date "+%s"`
ENDTIME=`expr "$NOWTIME" + "$DURATION"`
RV=0
while [ "$NOWTIME" -lt "$ENDTIME" ]; do
	NOWDIR=$NOWTIME
	mkdir $MMCSD_MOUNTPOINT_1/$NOWDIR
	cp -a /data $MMCSD_MOUNTPOINT_1/$NOWDIR
	ls -lR $MMCSD_MOUNTPOINT_1/$NOWDIR
	rm -Rf $MMCSD_MOUNTPOINT_1/$NOWDIR
	NOWTIME=`date "+%s"`
done

if [ "$RV" -eq "0" ]
then
	echo -e "PASS\n"
else
	echo -e "FAIL\n"
fi

exit $RV
	
