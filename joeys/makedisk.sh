CONVDIR="$PWD/mycode.conv"

###### Build the diskfile from the folder:

echo -n "Building disc ... "

## Init:
bbcim/bbcim -new disk.ssd
bbcim/bbcim -80 disk.ssd
# Did not appear to let BASIC write to extra space: bbcim/bbcim -max disk.ssd  (Probably the running ROM lacks support.)

## Add:
cd "$CONVDIR" || exit 1
# ../bbcim/bbcim -ab ../disk.ssd * || exit 1
# ../bbcim/bbcim -ab ../disk.ssd * | grep -v "^adding " | grep -v "^$"
for FILE in *
do
	if echo "$FILE" | grep "\.inf$" >/dev/null
	then continue
	fi
	INFFILE="$FILE".inf
	if [ -e "$INFFILE" ]
	then ../bbcim/bbcim -a ../disk.ssd "$FILE"
	else ../bbcim/bbcim -ab ../disk.ssd "$FILE"
	fi | dos2unix | grep -v "^adding " | grep -v "^$"
done
cd ..

echo "done."

## List:
bbcim/bbcim -c disk.ssd | tail -n 2



## Test:
SIZE=`du -sk "$CONVDIR" | takecols 1`
# SIZE=`du -sk disk.ssd`
if [ "$SIZE" -gt 120 ]
then jshwarn "Warning: $CONVDIR has size $SIZE""k!"
fi

## Deploy on laptop (for fast opening):
if [ -d DiscIms ] 
then mv -f disk.ssd DiscIms/
fi

