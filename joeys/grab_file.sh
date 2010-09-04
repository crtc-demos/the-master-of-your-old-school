if [ "$*" = "" ]
then ./bbcim/bbcim -c disk.ssd ; exit
fi

cd mycode.conv || exit 9

for FILE in "$@"
do
	../bbcim/bbcim -es ../disk.ssd "$FILE"
	# cat "$FILE" | sh ../fromunix.sh -tounix | dog "$FILE"
done

