#!/usr/bin/bash

# just a build script for running the build repo in docker container

docker_exec_bash() {
    local CONTAINER_NAME="$1"
    shift
    local COMMAND="$@"
    docker exec -it "$CONTAINER_NAME" bash -c "$COMMAND"
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

CONTAINER_NAME="dockdeb"
DOCKER_IMAGE="debian"
GITHUB_REPO="https://github.com/lnoxsian/debian-live-config.git"
GITHUB_REPO_DIR="debian-live-config-test"
GEN_ISO="live-image-amd64.hybrid.iso"

docker run -dt \
    --runtime=nvidia \
    --gpus all \
    --privileged \
    --cap-add=SYS_CHROOT \
    --name "$CONTAINER_NAME" \
    --hostname "${CONTAINER_NAME}local" \
    "$DOCKER_IMAGE"

docker_exec_bash "$CONTAINER_NAME" "apt update -y && apt upgrade -y && apt install make git sudo live-build -y"

docker_exec_bash "$CONTAINER_NAME" "git clone $GITHUB_REPO $GITHUB_REPO_DIR"

docker_exec_bash "$CONTAINER_NAME" "cd $GITHUB_REPO_DIR && make install_buildenv && make"

docker_copy "$CONTAINER_NAME" "/root/$GITHUB_REPO_DIR/$GEN_ISO" .
