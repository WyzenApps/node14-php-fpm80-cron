#!/bin/bash
. config.docker

TAG=${TAG:-"latest"}

docker build --rm -f Dockerfile --tag "${VENDOR}/${IMAGE}:${TAG}" .

