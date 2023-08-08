#!/usr/bin/env bash

set -eu

if [ $# -ne 1 ]; then
  echo "use ./run.sh <movies dir name>"
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

docker run --rm -it -v "$(pwd)/movies/$1:/movies" -v "$(pwd)/output/$1_$TIMESTAMP:/relion" relion