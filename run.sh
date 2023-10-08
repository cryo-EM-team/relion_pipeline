#!/usr/bin/env bash

set -eu

if [ $# -ne 1 ]; then
  echo "use ./run.sh <dataset name>"
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

docker run --rm -it --gpus all -v "$(pwd)/scripts/$1.sh:/setup/process.sh:ro" -v "$(pwd)/input/$1:/movies" -v "$(pwd)/output/$1/$TIMESTAMP:/relion" relion bash