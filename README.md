# cesium-proxy

## Quick Start
- Run: `docker compose up`

## Access services via the following URLs:
- App: http://map.localhost 
- MapProxy: http://mapproxy.map.localhost/demo

## Preload data
- Go into the docker: `docker exec -it --user=mapproxy cesium-proxy-mapproxy-1 bash`
- Then run: `mapproxy-seed -f mapproxy/mapproxy.yaml -s mapproxy/seed.yaml`

## Create terrain data
- Create terrain files: `docker run --rm -v ./terrain:/data tumgis/ctb-quantized-mesh ctb-tile -f Mesh -C -N -o /data /data/43536_Ortho_50.tif`
- Create layer description file: `docker run --rm -v ./terrain:/data tumgis/ctb-quantized-mesh ctb-tile -f Mesh -C -N -l -o /data /data/43536_Ortho_50.tif`
