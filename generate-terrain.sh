#!/bin/bash

# Check if an input file is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <input_tif_file>"
  exit 1
fi

# ---- step 1: get vars ----

# Assign the first argument (input file) to INPUT_FILE
INPUT_FILE="$1"
# Assign the second argument (output directory) to OUTPUT_DIR, defaulting to ./terrain if not provided
OUTPUT_DIR="${2:-./terrain}"
# Define a temporary file name for downloaded S3 inputs
INPUT_FILE_TMP=".tmp_file.tif"
# Define a temporary directory for intermediate terrain generation
OUTPUT_DIR_TMP="./.tmp_terrain"
# Create the temporary output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR_TMP"

# ---- step 2: load input file ----

# Check if the input file is an S3 path
if [[ "$INPUT_FILE" =~ ^s3://.* ]]; then
  
  # If it's an S3 path, check if AWS credentials are set
  if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "Error: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables must be set for S3 operations."
    exit 1
  fi
  echo "Downloading input file from S3: $INPUT_FILE"

  # Use a Dockerized AWS CLI to download the file from S3
  docker run --rm -it \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -v "$(pwd)":/aws \
    amazon/aws-cli s3 cp "$INPUT_FILE" "/aws/$INPUT_FILE_TMP"

else
  # If it's a local file, use the provided input file directly
  INPUT_FILE_TMP=$INPUT_FILE
fi

# ---- step 3: generate terrain ----

echo "Running ctb-tile for terrain generation... $INPUT_FILE_TMP"

# Run ctb-tile to generate terrain tiles with mercator projection
docker run --rm --user "$(id -u):$(id -g)" \
  -v $INPUT_FILE_TMP:/file.tif \
  -v $OUTPUT_DIR_TMP:/data \
  tumgis/ctb-quantized-mesh ctb-tile -p mercator -o /data /file.tif

# Run ctb-tile again to generate an additional layer (e.g., for shading or other data)  
docker run --rm --user "$(id -u):$(id -g)" \
  -v $INPUT_FILE_TMP:/file.tif \
  -v $OUTPUT_DIR_TMP:/data \
  tumgis/ctb-quantized-mesh ctb-tile -p mercator --layer -o /data /file.tif

# ---- step 4: Save generated assets ----

# Check if the output directory is an S3 path
if [[ "$OUTPUT_DIR" =~ ^s3://.* ]]; then
  # If it's an S3 path, check if AWS credentials are set
  if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "Error: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables must be set for S3 operations."
    exit 1
  fi
  echo "Uploading output to S3: $OUTPUT_DIR"
  # Use a Dockerized AWS CLI to upload the generated terrain files to S3
  docker run --rm -it \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -v $(pwd):/aws \
    amazon/aws-cli s3 cp $OUTPUT_DIR_TMP $OUTPUT_DIR --recursive
else
  # If it's a local path, remove any existing output directory and move the temporary output
  rm -rf $OUTPUT_DIR
  mv $OUTPUT_DIR_TMP $OUTPUT_DIR
fi

echo "Script finished. Output is in the '$OUTPUT_DIR' directory."
