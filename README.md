# Cesium Local Server Demo
This project demonstrates a CesiumJS application displaying a 3D globe with custom imagery, terrain, and 3D Tiles data served from a local server. This setup is ideal for working with proprietary datasets or developing offline Cesium applications.

## Features
- **Custom Imagery Layer:** Displays imagery directly from your local server.
- **Custom Terrain Layer:** Renders high-resolution terrain data sourced locally.
- **3D Tiles Integration:** Visualizes 3D models and point clouds using the OGC 3D Tiles standard, served from your internal infrastructure.
- **CesiumJS Viewer:** Configured with a basic Cesium viewer for navigation and interaction.

## Quick Start
```bash
git clone git@github.com:linnovate/cesium-proxy.git
cd cesium-proxy
docker compose up
```

## Access Services
You can access the deployed services via the following URLs:
- **App:** http://map.localhost 
- **MapProxy:** http://mapproxy.map.localhost/demo

## The files
- `/imagery` Contains custom imagery data served by MapProxy.
- `/terrain` Stores high-resolution terrain data generated for the application.
- `/3dtiles` Holds 3D Tiles datasets for visualization.
- `/compose.yml` Defines the Docker services and their configurations for the project.
- `/mapproxy.yaml` Configures the MapProxy server for imagery handling.
- `/seed.yaml` Specifies the seeding configuration for MapProxy to pre-generate imagery tiles.
- `/index.html` The main HTML file for the CesiumJS viewer.
- `/server.js` The Node.js server that serves the CesiumJS application and local data.

## Preload & Generate Data

### Import Imagery Proactively (via `mapproxy-seed`)
1. Enter the mapproxy Docker container: `docker exec -it --user=mapproxy cesium-proxy-mapproxy-1 bash`
2. Run the seed command: `mapproxy-seed -f mapproxy/mapproxy.yaml -s mapproxy/seed.yaml`
- Files will be placed in the `./imagery` folder.

### Generate Terrain from a TIF File (via `ctb-tile`)
1. Create terrain files (replace 'my_name.tif' with your file name): `docker run --rm -v ./terrain:/data tumgis/ctb-quantized-mesh ctb-tile -f Mesh -C -N -o /data /data/my_name.tif`
2. Create the layer description file (replace 'my_name.tif' with your file name): `docker run --rm -v ./terrain:/data tumgis/ctb-quantized-mesh ctb-tile -f Mesh -C -N -l -o /data /data/my_name.tif`
- Files will be placed in the `./terrain` folder.

### Obtain 3D Tiles (via `https://ion.cesium.com`)
1. Generate and download assets from: `https://ion.cesium.com/clips?page=1&sortOrder=ASC&sortBy=ID`
2. Unzip the data and place it in the `./3dtiles` folder.

## Notes
- To import imagery using `mapproxy` and `mapproxy-seed`, you need to use the direct API; it cannot be integrated via the Cesium UI.
- When serving terrain files from a local server, the response must include the headers: `--headers="Content-Type:application/vnd.quantized-mesh;Content-Encoding:gzip;"`.
- There are several methods to import images (`WMS, TMS`, or `static directory files`).
Currently, the `WMS` method is implemented, but the recommendation is to use `static directory files` imported and generated via MapProxy.
- `MapProxy` does not currently support the `terrain` format, so it cannot be imported in the same way as `imagery`.
- You can only work with `Stadia Maps` (https://tiles.stadiamaps.com) in Cesium using `WMS`, not `TMS`, due to an incompatible ZXY calculation.
- In CesiumJS 2D mode, there's a black artifact (or section) appearing due to terrain, likely only with its heightmap-1.0 format.
- In `offline` mode, MapProxy attempts to import incomplete data, which `overloads` the network until it `times out`.