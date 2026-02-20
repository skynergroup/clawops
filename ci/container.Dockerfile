FROM ubuntu:24.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates curl xorriso p7zip-full rsync coreutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
