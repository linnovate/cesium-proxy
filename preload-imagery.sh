#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -lt 4 ]; then
  echo "Usage: $0 <BBOX_LEFT> <BBOX_BOTTOM> <BBOX_RIGHT> <BBOX_TOP> <LELEVS> [OUTPUT_DIR]"
  echo "Example: $0 34.0 31.0 35.0 32.0 s3://my-bucket/imagery"
  exit 1
fi

# ---- step 1: get vars ----

# Assign the first four command-line arguments to environment variables.
export BBOX_LEFT="$1"
export BBOX_BOTTOM="$2"
export BBOX_RIGHT="$3"
export BBOX_TOP="$4"
export LELEVS="$5"

# Set OUTPUT_DIR to the fifth argument if provided, otherwise default to './imagery'.
OUTPUT_DIR="${6:-./imagery}"
# Define a temporary directory for intermediate files.
OUTPUT_DIR_TMP="./.tmp_imagery"
# Create the output and temporary directories if they don't already exist.
mkdir -p "$OUTPUT_DIR_TMP"

# ---- step 2: create settings file ----

# Create a JSON file in the temporary directory containing the bounding box coordinates.
echo "Saving BBOX environment variables to ${OUTPUT_DIR_TMP}/settings.json..."
cat << EOF > "${OUTPUT_DIR_TMP}/settings.json"
{
  "BBOX_LEFT": $BBOX_LEFT,
  "BBOX_BOTTOM": $BBOX_BOTTOM,
  "BBOX_RIGHT": $BBOX_RIGHT,
  "BBOX_TOP": $BBOX_TOP,
  "LELEVS": $LELEVS
}
EOF

# ---- step 3: generate MapProxy settings ----

echo "Generating mapproxy.yaml and seed.yaml from templates..."
# Ensure envsubst is available, if not, consider installing gettext-base (Debian/Ubuntu) or gettext (CentOS/RHEL)
if ! command -v envsubst &> /dev/null; then
  echo "Error: envsubst command not found. Please install it (e.g., 'sudo apt-get install gettext-base')."
  exit 1
fi
# Use envsubst to populate mapproxy.yaml & seed.yaml from its template, using the exported BBOX variables.
envsubst < mapproxy.yaml.template > mapproxy.yaml
envsubst < seed.yaml.template > seed.yaml

# ---- step 4: create mapproxy files ----

# Run the mapproxy-seed command inside a Docker container.
echo "Running mapproxy-seed for Imagery generation..."
docker run --rm \
  -v ./mapproxy.yaml:/mapproxy/mapproxy.yaml \
  -v ./seed.yaml:/mapproxy/seed.yaml \
  -v "$OUTPUT_DIR_TMP":/mapproxy/cache_data/imagery_cache_EPSG3857 \
  kartoza/mapproxy mapproxy-seed -f mapproxy.yaml -s seed.yaml

# ---- step 5: Save generated assets ----

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
    -e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
    -v ./:/aws \
    amazon/aws-cli s3 cp $OUTPUT_DIR_TMP $OUTPUT_DIR --recursive
else
  # If it's a local path, remove any existing output directory and move the temporary output
  rm -rf $OUTPUT_DIR
  mv $OUTPUT_DIR_TMP $OUTPUT_DIR
fi

echo "Script finished successfully. Output is in the '$OUTPUT_DIR' directory."

