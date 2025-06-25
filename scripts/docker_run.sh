#!/bin/bash

# Script to check Docker installation and set up a Debian container

# Set your Git repository URL here
REPO_URL="https://github.com/lnoxsian/debian-live-config.git"

# Container and image settings
CONTAINER_NAME="deblivebuild"
IMAGE_NAME="debian"
REPO_DIR="debian-live-config"

# Function to run a command inside the Docker container
docker_exec() {
    docker exec -it "$CONTAINER_NAME" bash -c "$1"
}

# Step 1: Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker and try again."
    exit 1
fi

echo "Docker is installed."

# Step 2: Run the Docker container
if docker ps -a --format '{{.Names}}' | grep -qw "$CONTAINER_NAME"; then
    echo "Container '$CONTAINER_NAME' already exists. Starting it..."
    docker start "$CONTAINER_NAME"
else
    echo "Creating and starting container '$CONTAINER_NAME'..."
    docker run -dt --privileged --cap-add SYS_CHROOT --name "$CONTAINER_NAME" --hostname deblivebld "$IMAGE_NAME"
fi

# Step 3: Run setup commands inside the container using the function
echo "Updating and installing packages inside the container..."
docker_exec "apt update -y && apt upgrade -y && apt install -y git sudo make"

# Step 4: Clone the Git repository
echo "Cloning repository: $REPO_URL"
if [ -d "$REPO_DIR" ]; then
    echo "$REPO_DIR does exist."
    docker_exec "cd $REPO_DIR; git pull"
else
    echo "$REPO_DIR does not exist."
    docker_exec "git clone $REPO_URL $REPO_DIR"
fi
docker_exec "git clone $REPO_URL $REPO_DIR"

# Step 5: Optional user command
read -p "Would you like to run the iso build now ? (y/n): " user_choice

BUILD_COMMAND="cd debian-live-config && make install_buildenv && make"

if [[ "$user_choice" =~ ^[Yy]$ ]]; then
    echo "Running build: $BUILD_COMMAND"
    docker_exec "$BUILD_COMMAND"
    echo "Copying the generated iso: live-image-amd64.hybrid.iso"
    docker cp $CONTAINER_NAME:/$REPO_DIR/live-image-amd64.hybrid.iso .
else
    echo "
    Skipping iso build.
    in order to run it
    docker exec -it $CONTAINER_NAME bash -c $BUILD_COMMAND
    "

fi

echo "All tasks complete."

