# RELION pipeline

## Requirements

- docker
- bash

## Building

- run: `./build.sh`

## Using

- copy dataset to `./input/<name>` (there should be images inside `<name>`)
- create pipeline script in `./scripts` named `<name>` using `relion_tutorial.sh` as a template
- run: `./run.sh <name>`
- outputs are in: `./output/<name>/<timestamp>`

# Tips

To use a separate hard drive for input and/or output use symlinks, for example:

- `ln -s /path/to/dataset ./input/<name>`
- `ln -s /path/to/output_dir ./output`