#!/bin/bash

INPUT_FILE="$1"
OUTPUT_DIR="./imagery"

# Run the first ctb-tile command
echo "Running mapproxy-seed for Imagery generation..."

source .env && docker run --rm \
  -v ./mapproxy.yaml:/mapproxy/mapproxy.yaml \
  -v ./seed.yaml:/mapproxy/seed.yaml \
  -v "$OUTPUT_DIR":/mapproxy/cache_data/imagery_cache_EPSG3857 \
  kartoza/mapproxy mapproxy-seed -f mapproxy.yaml -s seed.yaml

echo "Script finished. Output is in the '$OUTPUT_DIR' directory."



