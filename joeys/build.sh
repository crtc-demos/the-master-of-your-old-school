#!/bin/sh

## TODO: Refactor: This is a build, makedisk is way down the bottom.

## TODO: We could look at the contents of the disk and see if anything changed while the BBC was running.
##       If so, we may want to make a backup of that data file, or sync it into mycode/.
##       We should separate: data we want to edit on the Beeb and save locally,
##                           stuff that gets edited on the Beeb but we don't want to save,
##                           local stuff we don't really want the Beeb to change!

## TODO: compression?  remove "^REM.*" "^[ 	]*" ...

## DONE: To further conserve space, strip empty lines, and all indentation after line number.

SRCDIR="$PWD/mycode"
CONVDIR="$PWD/mycode.conv"
PREPROCESS=true
STRIP_COMMENTS=true ## generally we want to conserve space on our disk
STRIP_EMPTY_LINES=true ## ditto
TRIM_INDENTATION=true
## I hardly ever want this, I stopped using line numbers altogether with .BAS files. :P
# CREATE_RENUMBERED_FILE=true

[ -d "$SRCDIR" ] || exit 1

## man -l ./bbcim/doc/bbcim.m



###### Prepare/convert the Unix files to BBC files
## $SRCDIR -> $CONVDIR
## This include precompiling, renumbering, and formatting.

# verbosely rotate -max 5 "$SRCDIR" 2>/dev/null &
# mv -f disk.ssd disk.ssd.lastbuild && verbosely rotate -max 5 ./disk.ssd.lastbuild 2>/dev/null &
# wait
# verbosely rotate -max 5 "$CONVDIR"
# &&
# rm -rf "$CONVDIR/"
mkdir -p "$CONVDIR"

cd "$SRCDIR" || exit 2

echo -n "Doing macros... "
sh ./generate_macro.sh || exit 3
echo "done."

. importshfn newer
echo -n "Checking for updates: "

for SRCFILE in *
do

	## We skip files beginning . or _, with length>7, or containing .bas.<number> (hidden old version), or ending with ".renumbered".
	## Bah shouldn't we just have a few includes? :P
	## Yes!
	# if echo "$SRCFILE" | grep "\(^[._]\|^.\.........\|^[^.][^.][^.][^.][^.][^.][^.][^.]\|.*\.bas\.[0-9]\|\.renumbered$\|\.xescaped$\|\.before_renumber$\)" >/dev/null
	# then : # echo "- Skipping  $SRCFILE"
		# continue
	# fi

	if ! echo "$SRCFILE" | grep -i "\(^\$\.\!BOOT$\|\.exec$\|\.bas$\)" >/dev/null
	then continue
	fi

	## We strip any .bas extension:
	DESTFILE="$CONVDIR"/`echo "$SRCFILE" | sed 's+\.bas$++i'`

	## Should we transfer this file?
	if [ ! -f "$DESTFILE" ]
	then echo "* New       $SRCFILE" ## Definitely
	else
		if newer "$SRCFILE" "$DESTFILE"
		then echo ; echo "+ Changed   $SRCFILE" ## Definitely
		else
			## We don't think the file has changed, and it's already there - skip!
			echo -n "($SRCFILE) "
		  continue
		fi
	fi

	## OK so we are going to copy this file to the target, maybe after some preprocessing.

	if [ "$PREPROCESS" ]
	then

		### Update line-numbers for developer's copy:
		if [ "$CREATE_RENUMBERED_FILE" ]
		then cat "$SRCFILE" | sh ../bbcbasic_renumber.sh > "$SRCFILE.renumbered"
		fi
		## The final version is likely to run with a different set anyway, due to pre-processing.

		### Preprocess #defines and macros:
		## TODO: move bbcbasic_renumber to above jpp :P
		echo "  Converting: $SRCFILE -> $DESTFILE"
		# cat "$SRCFILE" |
		## highlightstderr had a bug with printing curse char to stdout
		highlightstderr \
		jpp -- "$SRCFILE" |

		if echo "$SRCFILE" | grep "\.BAS$" >/dev/null
		then
			#### Various other hacks to make writing jpp basic files more fun
			#### Personally I think that half of these transforms are dodgy and should only be run on .BAS files.
			#### Therefore .bas files will be able to escape the transforms, but not benefit from them.
			#### .bas files are close(r) to original BASIC, .BAS files are magic new style.
			# grep -v "^[ 	:]*;" | ## better do this first, or we might break commented lines!
			## Remove " ; blah" comments
			sed 's+\(^\|  *\);;* .*++' | ## ';'s are retained if no whitespace or newline before or after
			## Allow multiple ASM commands on one line if separated by ':'
			## To avoid breaking BASIC ':' separators, we require that either a 3-letter mnemonic or a '.' starting label follows the ':'.  Therefore, the BASIC command "END" may still be broken!
			sed 's+ : \([A-Z][A-Z][A-Z]\>\|\.[a-zA-Z0-9]*\>\|\]\( \|[ ]*$\)\)+\n 9999 \1+g' |
			sed 's+ : \([A-Z][A-Z][A-Z][A-Z]\>\|\.[a-zA-Z0-9]*\>\|\]\( \|[ ]*$\)\)+\n 9999 \1+g' |   # 4-letter copy of above (for EQUB etc.)
			sed 's+ : *$++' |
			## Slow and dirty, could be dropped: remove multi-line /* ... */ blocks
			escapenewlines | sed 's+/\*\([^*]*\|*[^/]\)*\*/++g' | unescapenewlines |
			if [ "$STRIP_COMMENTS" ]
			then grep -v "^[ 	0-9:]*\(REM\|;\)"
			else cat
			fi |
			### Fix line-numbers for output copy:
			# FAST=1 
			sh ../bbcbasic_renumber.sh -numall -run |
			if [ "$STRIP_EMPTY_LINES" ]
			then grep -v "^ *[0-9]* *$"
			else cat
			fi |
			if [ "$TRIM_INDENTATION" ]
			then sed 's+^ *\([0-9]*\) *+\1 +' ## Sorry I can't bear it without at least 1 space after the line number!
			else cat
			fi |
			## Allow ';' comments on their own line.  (Comes after renumber in case RENUM_ARGS is active.  Actually in current incarnation, it is always active here!)
			sed 's+^[	 ]*[0-9][0-9]*[	 ]*;+REM+' | ## Possibly redundant, weren't they already removed?
			## Converting to REMs is little use, what if we are inside ASM? :P
			### Strip # and REM comments from final output.
			## TODO: retain "^#define" but not "#^ ", then put this *before* jpp!
			##       Otherwise jpp/gcc can barf on line "# 10580 X%=0" with "error: "X" is not a valid filename"
			sed 's+^\(#\|//\)+REM \0+' |
			grep -v "^REM "
		else
			sh ../bbcbasic_renumber.sh $RENUM_ARGS |
			## TODO: These could be removed, to force "pure" basic for .bas files.
			sed 's+^\(#\|//\)+REM \0+' |
			grep -v "^REM "
		fi |

		## The developer can use a unix-readable copy of this file to check line numbers given by Basic errors.
		tee last_file_postproc.txt |
		# tee "$SRCFILE".out |

		## Finally we convert to Beeb style and put in output folder.
		../fromunix.sh |
		cat > "$DESTFILE"

		if [ "$CREATE_RENUMBERED_FILE" ]
		then
			if cmp "$SRCFILE" "$SRCFILE".renumbered >/dev/null
			then rm "$SRCFILE".renumbered
			else
				jshinfo "Line numbers were renamed in $SRCFILE"
				# jdiffsimple "$SRCFILE" "$SRCFILE.renumbered"
				diffsummary "$SRCFILE" "$SRCFILE.renumbered"
			fi
		fi

	else

		echo "  Copying: $SRCFILE -> $DESTFILE"
		cat "$SRCFILE" > "$DESTFILE"

	fi

	cursenorm

done
cd ..
echo



sh ./makedisk.sh

