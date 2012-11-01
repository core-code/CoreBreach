#!/bin/bash

cd "`dirname "$0"`"

for f in *
do
  echo "Processing $f file..."
  afconvert -f caff -d LEI16@44100 -c 1 "$f" "../sounds-caf/${f/wav/caf}"
done;