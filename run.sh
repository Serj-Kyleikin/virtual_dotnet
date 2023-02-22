#!/usr/bin/env bash

set -e

# dpkg --print-architecture - find out the linux architecture version
# find your VERSION here: https://mcr.microsoft.com/en-us/product/dotnet/sdk/tags

VERSION="7.0-alpine3.16-amd64"
IMAGE="mcr.microsoft.com/dotnet/sdk:$VERSION"

# Setup options for connecting to docker host
if [ -z "$DOCKER_HOST" ]; then
    DOCKER_HOST="/var/run/docker.sock"
fi

if [ -S "$DOCKER_HOST" ]; then
    DOCKER_ADDR="-v $DOCKER_HOST:$DOCKER_HOST -e DOCKER_HOST"
else
    DOCKER_ADDR="-e DOCKER_HOST -e DOCKER_TLS_VERIFY -e DOCKER_CERT_PATH"
fi

# Setup volume mounts
if [ "$(pwd)" != '/' ]; then
    VOLUMES="-v $(pwd):$(pwd)"
fi

if [ -n "$HOME" ]; then
    VOLUMES="$VOLUMES -v $HOME:$HOME -e HOME" # Pass in HOME to allow ~/-relative paths to work.
fi

# Only allocate tty if we detect one
if [ -t 0 ] && [ -t 1 ]; then
    DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS -t"
fi

# Always set -i to support piped and terminal input in run/exec
DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS -i"

# Handle userns security
if docker info --format '{{json .SecurityOptions}}' 2>/dev/null | grep -q 'name=userns'; then
    DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS --userns=host"
fi

# Run as the current user on Linux (the docker daemon runs as root)
if [ "$(uname -s)" = 'Linux' ]; then
    DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS -u $(id -u ${USER}):$(id -g ${USER})"
fi

# shellcheck disable=SC2086
exec docker run --rm $DOCKER_RUN_OPTIONS $DOCKER_ADDR $VOLUMES -w "$(pwd)" $IMAGE dotnet "$@"
