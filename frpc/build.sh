#!/bin/sh

DOCKER_HUB_PROJECT=snowdreamtech/frpc

GITHUB_PROJECT=ghcr.io/snowdreamtech/frpc

docker buildx build --platform=linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64,linux/ppc64le,linux/riscv64,linux/s390x-dev\
-t ${DOCKER_HUB_PROJECT}:latest-dev\
-t ${DOCKER_HUB_PROJECT}:0.58.1-r1-dev\
-t ${DOCKER_HUB_PROJECT}:0.58.1-dev\
-t ${DOCKER_HUB_PROJECT}:0.58-dev\
-t ${DOCKER_HUB_PROJECT}:0-dev\
-t ${GITHUB_PROJECT}:latest-dev\
-t ${GITHUB_PROJECT}:0.58.1-r1-dev\
-t ${GITHUB_PROJECT}:0.58.1-dev\
-t ${GITHUB_PROJECT}:0.58-dev\
-t ${GITHUB_PROJECT}:0-dev\
.\
--push
