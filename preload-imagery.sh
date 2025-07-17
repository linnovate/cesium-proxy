#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -lt 4 ]; then
  echo "Usage: $0 <BBOX_LEFT> <BBOX_BOTTOM> <BBOX_RIGHT> <BBOX_TOP> [OUTPUT_DIR]"
  echo "Example: $0 34.0 31.0 35.0 32.0 s3://my-bucket/imagery"
  exit 1
fi

# Export bounding box coordinates
export BBOX_LEFT="$1"
export BBOX_BOTTOM="$2"
export BBOX_RIGHT="$3"
export BBOX_TOP="$4"

# Set output directories
OUTPUT_DIR="${5:-./imagery}"
OUTPUT_DIR_TMP="./.tmp_imagery"

mkdir -p "$OUTPUT_DIR"

echo "Generating mapproxy.yaml and seed.yaml from templates..."
# Ensure envsubst is available, if not, consider installing gettext-base (Debian/Ubuntu) or gettext (CentOS/RHEL)
if ! command -v envsubst &> /dev/null; then
  echo "Error: envsubst command not found. Please install it (e.g., 'sudo apt-get install gettext-base')."
  exit 1
fi

envsubst < mapproxy.yaml.template > mapproxy.yaml
envsubst < seed.yaml.template > seed.yaml
   
mkdir -p "$OUTPUT_DIR_TMP"

# Run the first ctb-tile command
echo "Running mapproxy-seed for Imagery generation..."
docker run --rm \
  -v ./mapproxy.yaml:/mapproxy/mapproxy.yaml \
  -v ./seed.yaml:/mapproxy/seed.yaml \
  -v "$OUTPUT_DIR_TMP":/mapproxy/cache_data/imagery_cache_EPSG3857 \
  kartoza/mapproxy mapproxy-seed -f mapproxy.yaml -s seed.yaml

if [[ "$OUTPUT_DIR" =~ ^s3://.* ]]; then
  if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "Error: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables must be set for S3 operations."
    exit 1
  fi
  echo "Uploading output to S3: $OUTPUT_DIR"
  docker run --rm -it -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY $(pwd):/aws amazon/aws-cli s3 cp $OUTPUT_DIR_TMP $OUTPUT_DIR --recursive
else
  rm -rf $OUTPUT_DIR
  mv $OUTPUT_DIR_TMP $OUTPUT_DIR
fi

echo "Script finished successfully. Output is in the '$OUTPUT_DIR' directory."

