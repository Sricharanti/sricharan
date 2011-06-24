#!/bin/sh
if [ $# -lt 3 ]; then
	echo "invalid options"
	exit 1
fi

ROW_ADD=2
DELAY=0
BUS=$1
shift
REG=$1
shift
DATA=$1

while true
do
	shift
	OPTIONS=$1

	if [ "$OPTIONS" = "-h" ]; then
		ROW_ADD=3
	elif [ "$OPTIONS" = "-d" ]; then
		shift 
		DELAY=$1
	elif [ -z "$OPTIONS" ]; then
		break;		
	fi	
done

DATA_DEC=`printf "%d" $DATA`
COL=`echo "( $DATA_DEC %16)+2"|bc`
ROW=`echo "( $DATA_DEC /16) +$ROW_ADD"|bc`

if [ -z "$count" ]; then
	count=0
fi

#Write an incremental data pattern
while [ $count -lt 8 ]
do
	data_byte=`echo "0+$count"|bc`
	data_hex=`printf "0x%x" $data_byte`
	
	# Let's write to i2c bus
	i2cset -f -y $OPTIONS $BUS $REG $DATA $data_hex b
	
	if [ $? -ne 0 ]; then
		echo "Failed in i2cset"
		exit 1
	fi
	
	# Get data from i2c bus
	data_read=`i2cdump -f -y $OPTIONS $BUS $REG b | cut -d ' ' -f $COL | head $I2C_HEAD_OPTION $ROW | tail $I2C_TAIL_OPTION 1`
	
	if [ $? -ne 0 ]; then
		echo "Failed in i2cdump"
		exit 2
	fi
	
	data_read_byte=`printf "%d" "0x$data_read"`
	if [ $data_byte -eq $data_read_byte ]; then
		echo $count success $data_read_byte $data_byte
	else
		echo $count fail $data_read_byte $data_byte
		exit 3
	fi
	count=`expr $count + 1`
	sleep $DELAY
done
