#!/bin/env bash
#
# Generate index of all script metadata
#

TMP_FILE_NAME=/tmp/temp.json
RESULT_FILE_NAME=index.json

echo "[" > ${TMP_FILE_NAME}

# Search for all files named "info.json" and store their paths in an array
files=( $(find . -name "info.json") )

# Loop through the array of files and concatenate their contents into a new file
for (( i=0; i<${#files[@]}; i++ ))
do
  cat "${files[i]}" >> ${TMP_FILE_NAME}
  if [ $i -ne $((${#files[@]}-1)) ]
  then
    echo "," >> ${TMP_FILE_NAME}
  fi
done

echo "]" >> ${TMP_FILE_NAME}

# Minify json
jq -r tostring < ${TMP_FILE_NAME} > ${RESULT_FILE_NAME}

echo "Done! Concatenated info.json files can be found in ${RESULT_FILE_NAME}."
