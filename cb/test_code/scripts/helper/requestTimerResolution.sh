#!/bin/sh

IS_NSECS=`cat /proc/timer_list | grep -w '.resolution: 1 nsecs' | wc -l`

[ $IS_NSECS ] && exit 0 || exit 1

# End of file
