#/bin/bash

if [ "$1" = -all ]
then

  ./grab_file.sh |
  takecols 1 | fromline -x "^File$" | toline -x '^$' |
  # pipeboth |
  # foreachdo verbosely ./grab_file.sh "$fname"
  while read fname
  do ( verbosely ./grab_file.sh "$fname" ) &
  done

  exit
fi

if [ "$*" = "" ]
then ./bbcim/bbcim -c disk.ssd ; exit
fi

cd mycode.conv || exit 9

for FILE in "$@"
do
  ../bbcim/bbcim -es ../disk.ssd "$FILE"
  # cat "$FILE" | sh ../fromunix.sh -tounix | dog "$FILE"
done

cd ..

