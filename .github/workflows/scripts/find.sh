#!/bin/env bash

echo "[" >> concatenated_info.json

# Search for all files named "info.json" and store their paths in an array
files=( $(find . -name "info.json") )

# Loop through the array of files and concatenate their contents into a new file
for (( i=0; i<${#files[@]}; i++ ))
do
  cat "${files[i]}" >> concatenated_info.json
  if [ $i -ne $((${#files[@]}-1)) ]
  then
    echo "," >> concatenated_info.json
  fi
done

echo "]" >> concatenated_info.json

echo "Done! Concatenated info.json files can be found in concatenated_info.json."

