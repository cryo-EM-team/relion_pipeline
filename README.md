# relion docker

## Requirements

- linux
- docker
- bash

## Building image

- run: `./build.sh`

## Using the pipeline

- copy movies to `./movies/<name>` (there should be *.tiff inside `<name>`)
- run: `./run.sh <name>`
- outputs are in: `./output/<name>_<timestamp>`