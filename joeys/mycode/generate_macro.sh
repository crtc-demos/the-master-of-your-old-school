## Takes a file containing an ASM or BASIC snippet, and puts it all on one line
## in order to create a CPP Macro with the same name as the file.

## If the macro requires arguments, a line should be included in the file:
## ; @expects _arg1name, _arg2name, _arg3name

for FILE in _*.jpp
do

	MACRO_NAME="$(basename "$FILE" .jpp)"
	OUTFILE="$MACRO_NAME.macro"

	ARGS=$(grep "@expects " "$FILE" | sed 's+.*@expects ++')
	[[ "$ARGS" ]] && ARGS="($ARGS)"

	(

		echo
		echo ";;; WARNING: This file was auto-generated.  Changes will be lost!  Edit $FILE instead. ;;;"
		echo

		echo -n "#define $MACRO_NAME$ARGS "

		cat "$FILE" |
		sed 's+\(^;\| ;\).*++' |
		grep -v "^$" | sed 's+$+ : +' | tr -d '\n'

		echo

	) | dog "$OUTFILE"

done

