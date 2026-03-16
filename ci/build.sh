#!/usr/bin/env bash
set -euo pipefail

make clean
make

mkdir -p out
cp ./matrix ./out/matrix
chmod +x ./out/matrix

echo "Build completed: ./out/matrix"