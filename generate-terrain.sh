#!/bin/bash

# Check if an input file is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <input_tif_file>"
  exit 1
fi

INPUT_FILE="$1"
OUTPUT_DIR="./terrain"

# Run the first ctb-tile command
echo "Running ctb-tile for terrain generation..."
docker run --rm --user "$(id -u):$(id -g)" -v $INPUT_FILE:/file.tif -v $OUTPUT_DIR:/data tumgis/ctb-quantized-mesh ctb-tile -p mercator -o /data /file.tif
docker run --rm --user "$(id -u):$(id -g)" -v $INPUT_FILE:/file.tif -v $OUTPUT_DIR:/data tumgis/ctb-quantized-mesh ctb-tile -p mercator --layer -o /data /file.tif

echo "Script finished. Output is in the '$OUTPUT_DIR' directory."
