#!/usr/bin/bash

# just a build script for running the build repo in docker container

docker_exec() {
    local CONTAINER_NAME="$1"
    shift
    local COMMAND="$@"
    docker exec -it "$CONTAINER_NAME" $COMMAND
}

# Function to copy file from container to host
docker_copy() {
    local CONTAINER_NAME="$1"
    local SRC_PATH="$2"
    local DEST_PATH="$3"
    docker cp "${CONTAINER_NAME}:${SRC_PATH}" "${DEST_PATH}"
}

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <container_name> <docker_image>"
    exit 1
fi

CONTAINER_NAME="$1"
DOCKER_IMAGE="$2"
GITHUB_REPO="https://github.com/lnoxsian/debian-live-config.git"
GITHUB_REPO_DIR="debian-live-config"

docker run -dt \
    --runtime=nvidia \
    --gpus all \
    --privileged \
    --cap-add=SYS_CHROOT \
    --name "$CONTAINER_NAME" \
    --hostname "${CONTAINER_NAME}local" \
    "$DOCKER_IMAGE"

docker_exec "$CONTAINER_NAME" bash -c "git clone $GITHUB_REPO $GITHUB_REPO_DIR"

docker_exec "$CONTAINER_NAME" bash -c "apt update -y && apt upgrade -y && apt install make git sudo live-build -y"

docker_exec "$CONTAINER_NAME" bash -c "cd $GITHUB_REPO_DIR && make install_buildenv && make"
