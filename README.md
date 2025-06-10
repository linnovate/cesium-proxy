# cesium-proxy

## Quick Start
- Run: `docker compose up`

## Access services via the following URLs:
- App: http://map.localhost 
- MapProxy: http://mapproxy.map.localhost/demo

## Preload data
- Go into the docker: `docker exec -it cesium-proxy-mapproxy-1 bash`
- Then run: `mapproxy-seed -f mapproxy/mapproxy.yaml -s mapproxy/seed.yaml`
