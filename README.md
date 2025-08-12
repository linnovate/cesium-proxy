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

## Data Pre-loading and Generation: User Guide

### Obtain Imagery Map
**Imagery** of a map refers to the visual representation of the Earth's surface, serving as a foundational layer for geographic understanding.
You can add multiple layers on top of each other, such as a layer of more recent images or ones containing different features.

To streamline data access and enable offline capabilities, we utilize [MapProxy](https://mapproxy.org). This setup facilitates quick and easy local image storage. MapProxy is also configured with a specific bounding box; any request outside of this area will return empty space (white space).

The approximate file sizes per 1000m x 1000m area at different zoom levels are:
- **Level 0-14:** (~85 KB * 15) = ~1.2 MB
- **Level 15-16:** (~300 KB * 2) = ~600 KB
- **Level 17:** ~1 MB
- **Level 18:** ~2.5 MB
- **Level 19:** ~7.6 MB
- **Total Estimated Size:** ~13 MB

*the Calculation:*
- 1 tile size: `~60k, 256px/256px`
- 1 tile meters: level 0 = `156,543.03` / level 16 = `2.388` / level 20 = `0.149`.

To configure the bounding box coordinates, follow these steps:
1. **Update BBOX Environment Variables:** Run the following code in your project directory's terminal, replacing the example coordinates with your desired bounding box coordinates (in `EPSG:3857` format):
   ```bash
   # Example bounding box coordinates (replace with your values)
   export BBOX_LEFT=3813950
   export BBOX_BOTTOM=3486300
   export BBOX_RIGHT=4014900
   export BBOX_TOP=3968200
   export LEVELS=10
   # Apply the variables to the template files
   envsubst < mapproxy.yaml.template > mapproxy.yaml
   envsubst < seed.yaml.template > seed.yaml
   ```
   After making these changes, remember to restart your Docker Compose agent to ensure the new configurations are loaded.
2. **Manually Preload Data:** Navigate to your project directory in the terminal or command prompt and execute the following command:
   ```bash
   # Example: ./preload-imagery.sh <BBOX_LEFT> <BBOX_BOTTOM> <BBOX_RIGHT> <BBOX_TOP> <LEVELS> [OUTPUT_DIR]
   ./preload-imagery.sh 3813950 3486300 4014900 3968200 10 ./imagery
   # Example S3:
   AWS_ACCESS_KEY_ID= AWS_SECRET_ACCESS_KEY= AWS_DEFAULT_REGION= CACHE_TYPE=file|s3 ./preload-imagery.sh 3813950 3486300 4014900 3968200 10 s3://.../imagery
   ```
3. **Add to Cesium UI:** Incorporate the imagery layer into your Cesium application using the following JavaScript code:
   ```js
   /* Using static files */
   // ...
   viewer.imageryLayers.addImageryProvider(new Cesium.UrlTemplateImageryProvider({
     url: '/imagery/{z}/000/000/{x}/000/000/{y}.png',
     urlSchemeZeroPadding: { '{z}': '00', '{x}': '000', '{y}': '000' },
     credit: 'Imagery from MapProxy',
     tilingScheme: new Cesium.WebMercatorTilingScheme(),
     minimumLevel: 0,
     maximumLevel: 10,
   }));
   ```
   ```js
   /* Using WMS MapProxy server */
   // ...
   viewer.imageryLayers.addImageryProvider(new Cesium.WebMapServiceImageryProvider({
     url: "http://mapproxy.map.localhost/service?", 
     layers: 'mapproxy',
     parameters: {
       layers: "imagery",
       format: 'image/png',
     }
   }));
   ```
   
### Obtain Terrain Map
A **terrain map** uses contour lines to represent the elevation and shape of the land surface, illustrating features like hills, valleys, and slopes.

Terrain information can be obtained from the following common formats (often found in TIFF files):
- DEM (Digital Elevation Model)
- DTM (Digital Terrain Model)
- DSM (Digital Surface Model)

The weight of files are:
- Relative to the area. The higher the zoom level, the greater the weight; the total overall size can be up to 2 times the original TIFF file size.

To obtain and process a terrain map, follow these steps:
1. **Download TIF File:** Acquire a TIF file from a service like [OpenTopography](https://portal.opentopography.org/raster?opentopoID=OTSDEM.032021.4326.3).
2. **Generate Terrain Tiles:** Navigate to your project directory in the terminal or command prompt and execute the following command:
   ```bash
   # Example: ./generate-terrain.sh [INPUT_FILE] [OUTPUT_DIR]
   ./generate-terrain.sh ./your_file.tif ./terrain
   # Example S3:
   AWS_ACCESS_KEY_ID= AWS_SECRET_ACCESS_KEY= AWS_DEFAULT_REGION= ./generate-terrain.sh s3://.../your_file.tif s3://.../terrain
   ```
 3. **Add to Cesium UI:** Incorporate the imagery layer into your Cesium application using the following JavaScript code:
      ```js
      // ...
      viewer.terrainProvider = await Cesium.CesiumTerrainProvider.fromUrl('/your_folder');
      ```
  
*Note: Unlike 3D tiles, this is a single instance of a map display, functioning solely to provide information about static surfaces.*

### Obtain 3D Tiles
**3D Tiles** is a hierarchical data structure for streaming 3D geospatial content such as buildings. It allows for the inclusion of multiple assets.

The weight of files are:
- The original size received.

To get 3D Tiles, follow these steps:
1. **Sign In:** Go to https://ion.cesium.com/signin and sign in to your Cesium ion account.
2. **Create a Clip:**
   - Navigate to the "Clips" section at https://ion.cesium.com/clips and select "Create clip".
   - Alternatively, go directly to https://ion.cesium.com/clips/create.
3. **Configure Clipping Options:**
   - **Select Clip Type:** Choose **"Clip 3D Tiles"**.
   - **Select 3D Tiles:** Select the desired 3D Tiles from the provided list.
   - **Select Region:** Use the interactive map to draw a rectangular or polygonal area that you want to clip.
   - **Clip options:** Specify "3D Tiles" as the output format and adjust any other relevant settings.
4. **Generate and download:** Once Cesium ion finishes processing your request, you can download the generated clip from https://ion.cesium.com/clips.
5. **Unzip and Place File:** After downloading the file, **unzip** it and place its contents into the `./3dtiles` folder of your project.
6. **Add to Cesium UI:** Incorporate the imagery layer into your Cesium application using the following JavaScript code:
   ```js
   // ...
   const tileset = await Cesium.Cesium3DTileset.fromUrl('/your_folder/tileset.json')
   viewer.scene.primitives.add(tileset);
   ```

*Note: You can generate 3D Tiles from GLB/GLTF files using the tools https://github.com/CesiumGS/3d-tiles-tools and https://github.com/CesiumGS/gltf-pipeline.*

## Files Structure
- `/imagery` Contains custom imagery data served by MapProxy.
- `/terrain` Stores high-resolution terrain data generated for the application.
- `/3dtiles` Holds 3D Tiles datasets for visualization.
- `/compose.yml` Defines the Docker services and their configurations for the project.
- `/mapproxy.yaml` Configures the MapProxy server for imagery handling.
- `/seed.yaml` Specifies the seeding configuration for MapProxy to pre-generate imagery tiles.
- `/index.html` The main HTML file for the CesiumJS viewer.
- `/server.js` The Node.js server that serves the CesiumJS application and local data.

## Notes
- To import imagery using `mapproxy` and `mapproxy-seed`, you need to use the direct API; it cannot be integrated via the Cesium UI.
- When serving terrain files from a local server, the response must include the headers: `--headers="Content-Type:application/vnd.quantized-mesh;Content-Encoding:gzip;"`.
- There are several methods to import images (`WMS, TMS`, or `static directory files`).
Currently, the `WMS` method is implemented, but the recommendation is to use `static directory files` imported and generated via MapProxy.
- `MapProxy` does not currently support the `terrain` format, so it cannot be imported in the same way as `imagery`.
- You can only work with `Stadia Maps` (https://tiles.stadiamaps.com) in Cesium using `WMS`, not `TMS`, due to an incompatible ZXY calculation.
- In `offline` mode, MapProxy attempts to import incomplete data, which `overloads` the network until it `timeout`. To prevent this, you must set the coverage to match that of the preloaded data.
