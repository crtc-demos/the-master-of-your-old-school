addr=0x8000
while read file; do
  size=$(find "$file" -printf "%s")
  echo "	.word $(printf "%x" $addr)"
  addr=$(( $addr + $size ))
done < order

while read file; do
  cat "$file"
done < order > tune
