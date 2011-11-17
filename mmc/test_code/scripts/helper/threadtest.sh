#echo "$$"
#$MMCSD_DIR_HELPER/cpcmp.sh $MMCSD_FILE_SIZE_BIG $MMCSD_TMPFS_MOUNTPOINT $MMCSD_MOUNTPOINT_1
BASEFN=$1
SRCDIR=$2
DESTDIR=$3
LIMIT=10
cnt=0

a=0
while [ "$a" -lt "$LIMIT" ]
do
	( cp $SRCDIR/$BASEFN $DESTDIR/$BASEFN$a ) &
	bpid=$!
	eval pid$a=\"$bpid\"
	let cnt+=1
	let a+=1
done

echo "waiting nicely for $cnt threads"
a=1
while [ "$a" -ne "0" ]
do
	a=0

	b=0
	while [ "$b" -lt "$cnt" ]
	do
		tmp2=`eval echo \\$pid$b`
		if [ -n "$tmp2" ]; then
			tmp=$(($(dd if=/dev/urandom count=1 2> /dev/null | cksum | cut -d' ' -f1) % 5))
			renice -n $tmp -p $tmp2 2>/dev/null
			rnv=$?
			if [ "$rnv" -ne "0" ]; then
				eval pid$b=
			else
				let a=a+1
			fi
		fi
		let b+=1
	done
	echo -n "$a"
done

echo "comparing"
a=0
while [ "$a" -lt "$LIMIT" ]
do
	if ! cmp $SRCDIR/$BASEFN $DESTDIR/$BASEFN$a ; then
		exit 1
	fi
	let a+=1
done
exit 0

