#!/bin/sh

i=$1
sleepno=$2
if [ -z "$sleepno" ]; then
	sleepno=0
fi
while [ 0 -le $i ]
do
  cat $DEVFS_TEMP
  RET=$?
  if [ "$RET" = "0" ]; then
  	  #wait for some time then take another reading
  	  echo -n "."
  	  sleep $sleepno;
  else
  	  echo "error"
  	  exit $RET
  fi
  i=`expr $i - 1`
done
exit 0

