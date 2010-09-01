## The ^@ speshl characters are not properly recreated by this sed.
## But this seems to do well enough on files for *EXEC'ing on BBC boot.

if [ "$1" = -tounix ]
then TOUNIX=true; shift
fi

doit() {
	if [ "$TOUNIX" ]
	then sed 's+ +\
+g'
	else sed 's+$+ +' | tr -d '\n'
	fi
}

if [ "$*" ]
then

	for FILE
	do
		cat "$FILE" |
		doit
		# | dog "$FILE"
	done

else

	doit

fi
