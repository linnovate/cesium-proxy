#!/bin/bash

# Check if an input file is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <input_tif_file>"
  exit 1
fi

INPUT_FILE="$1"
OUTPUT_DIR="${2:-./terrain}"
INPUT_FILE_TMP=".tmp_file.tif"
OUTPUT_DIR_TMP="./.tmp_terrain"

mkdir -p "$OUTPUT_DIR_TMP"

if [[ "$INPUT_FILE" =~ ^s3://.* ]]; then
  echo "Downloading input file from S3: $INPUT_FILE"
  docker run --rm -it -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY $(pwd):/aws amazon/aws-cli s3 cp $INPUT_FILE /aws/$INPUT_FILE_TMP
else
  INPUT_FILE_TMP=$INPUT_FILE
fi

echo "Running ctb-tile for terrain generation... $INPUT_FILE_TMP"
docker run --rm --user "$(id -u):$(id -g)" -v $INPUT_FILE_TMP:/file.tif -v $OUTPUT_DIR_TMP:/data tumgis/ctb-quantized-mesh ctb-tile -p mercator -o /data /file.tif
docker run --rm --user "$(id -u):$(id -g)" -v $INPUT_FILE_TMP:/file.tif -v $OUTPUT_DIR_TMP:/data tumgis/ctb-quantized-mesh ctb-tile -p mercator --layer -o /data /file.tif

if [[ "$OUTPUT_DIR" =~ ^s3://.* ]]; then
  echo "Uploading output to S3: $OUTPUT_DIR"
  docker run --rm -it -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY $(pwd):/aws amazon/aws-cli s3 cp $OUTPUT_DIR_TMP $OUTPUT_DIR --recursive
else
  rm -rf $OUTPUT_DIR
  mv $OUTPUT_DIR_TMP $OUTPUT_DIR
fi

echo "Script finished. Output is in the '$OUTPUT_DIR' directory."

