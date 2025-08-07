#!/usr/bin/bash
# wget https://raw.githubusercontent.com/lnoxsian/debian-live-config/main/scripts/dockbuild.sh && bash dockbuild.sh
# just a build script for running the build repo in docker container
filter_progress() {
  grep -v -E '^\[.*%.*\]|Downloading|Preparing|Installing|^Progress:|Collecting'
}

log_and_show() {
  # Generates logfile name with current date and time
  logfile="log_$(date '+%Y-%m-%d_%H-%M-%S').txt"
  # Run the command, show output, and append to the log file
  exec > >(tee >(filter_progress >> "$logfile")) 2>&1
}

docker_exec_bash() {
    local CONTAINER_NAME="$1"
    shift
    local COMMAND="$@"
    docker exec -it "$CONTAINER_NAME" bash -c "$COMMAND"
}

# Function to stop the docker container
docker_stop() {
    local CONTAINER_NAME="$1"
    docker stop "$CONTAINER_NAME"
}

# Function to copy file from container to host
docker_copy() {
    local CONTAINER_NAME="$1"
    local SRC_PATH="$2"
    local DEST_PATH="$3"
    docker cp "${CONTAINER_NAME}:${SRC_PATH}" "${DEST_PATH}"
}

# Function for creating the docker container
docker_run() {
    local CONTAINER_NAME="$1"
    local DOCKER_IMAGE="$2"
    docker run -dt \
        --rm \
        --privileged \
        --cap-add=SYS_CHROOT \
        --name "$CONTAINER_NAME" \
        --hostname "${CONTAINER_NAME}local" \
        "$DOCKER_IMAGE"
}


# Default values for the env vars
CONTAINER_NAME="dockdeb"
DOCKER_IMAGE="debian"

# my custom build for the repo
GITHUB_REPO="https://github.com/lnoxsian/debian-live-config.git"

# original build for the repo
# GITHUB_REPO="https://gitlab.com/nodiscc/debian-live-config.git" # this is for the original repo build into
#
GITHUB_REPO_DIR="debian-live-config-test"
GEN_ISO="live-image-amd64.hybrid.iso"

# log_and_show # running the logger for the exec

echo "[1]:Creating the docker container"
docker_run "$CONTAINER_NAME" "$DOCKER_IMAGE"

echo "[2]:Installing build deps git sudo live-build etc.. "
docker_exec_bash "$CONTAINER_NAME" "apt update -y && apt upgrade -y && apt install make git sudo live-build -y"

echo "[3]:Cloning and pulling the git repo"
docker_exec_bash "$CONTAINER_NAME" "git clone $GITHUB_REPO $GITHUB_REPO_DIR"

echo "[4]:Creating starting the build "
docker_exec_bash "$CONTAINER_NAME" "cd $GITHUB_REPO_DIR && make install_buildenv && make"

echo "[5]:Copying the iso that was build from the container"
docker_copy "$CONTAINER_NAME" "/$GITHUB_REPO_DIR/$GEN_ISO" .

echo "[6]:Removing the docker container"
docker_stop "$CONTAINER_NAME" 
