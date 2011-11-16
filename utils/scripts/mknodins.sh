if [ ! -c /dev/input/event0 ]
then
  mknod /dev/input/event0 c 13 64
fi
if [ ! -c /dev/input/event1 ]
then
  mknod /dev/input/event1 c 13 65
fi
if [ ! -c /dev/input/event2 ]
then
  mknod /dev/input/event2 c 13 66
fi
if [ ! -c /dev/input/event3 ]
then
  mknod /dev/input/event3 c 13 67
fi
if [ ! -c /dev/input/event4 ]
then
  mknod /dev/input/event4 c 13 68
fi
if [ ! -c /dev/input/event5 ]
then
  mknod /dev/input/event5 c 13 69
fi
if [ ! -c /dev/input/event6 ]
then
  mknod /dev/input/event6 c 13 70
fi
if [ ! -c /dev/input/event7 ]
then
  mknod /dev/input/event7 c 13 71
fi
if [ ! -c /dev/input/event8 ]
then
  mknod /dev/input/event8 c 13 72
fi
if [ ! -c /dev/input/event9 ]
then
  mknod /dev/input/event9 c 13 73
fi
