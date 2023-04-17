#!/bin/env bash
#
# Generate index of all script metadata
#

FILE_NAME=index.json

echo "[" >> ${FILE_NAME}

# Search for all files named "info.json" and store their paths in an array
files=( $(find . -name "info.json") )

# Loop through the array of files and concatenate their contents into a new file
for (( i=0; i<${#files[@]}; i++ ))
do
  cat "${files[i]}" >> ${FILE_NAME}
  if [ $i -ne $((${#files[@]}-1)) ]
  then
    echo "," >> ${FILE_NAME}
  fi
done

echo "]" >> ${FILE_NAME}

echo "Done! Concatenated info.json files can be found in ${FILE_NAME}."
