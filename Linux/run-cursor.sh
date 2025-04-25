#!/bin/bash

# Create projects directory if it doesn't exist
mkdir -p ~/cursor-projects

# First, make sure xhost allows connections from localhost
xhost +local:

# Build the Docker image
echo "Building Cursor container image..."
docker build -t cursor-firefox-ppa -f Dockerfile .

# Get current user ID
USER_ID=$(id -u)

# Initialize Docker volumes with correct permissions if they don't exist
# This helps avoid permission issues with Docker volumes
echo "Setting up Docker volumes with correct permissions..."
docker volume create cursor_app_data
docker volume create cursor_config_data
docker volume create firefox_profile_data

# Optional: Run a one-time permissions fix on existing volumes
# Uncomment this section if you're still having issues after rebuilding
# docker run --rm -it \
#   -v cursor_app_data:/cursor_app_data \
#   -v cursor_config_data:/cursor_config_data \
#   -v firefox_profile_data:/firefox_profile_data \
#   ubuntu:22.04 \
#   /bin/bash -c "mkdir -p /cursor_app_data/extensions && chmod -R 777 /cursor_app_data && chmod -R 777 /cursor_config_data && chmod -R 777 /firefox_profile_data"

# Run using X11 forwarding with proper volume mounts
echo "Starting Cursor container..."
docker run -it --rm \
  --name cursor-instance \
  --hostname cursor-container \
  --net=host \
  -e DISPLAY=$DISPLAY \
  -e XAUTHORITY=$HOME/.Xauthority \
  -v $HOME/.Xauthority:/home/cursoruser/.Xauthority:ro \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v cursor_app_data:/home/cursoruser/.cursor \
  -v cursor_config_data:/home/cursoruser/.config/Cursor \
  -v firefox_profile_data:/home/cursoruser/.mozilla/firefox \
  -v ~/cursor-projects:/home/cursoruser/projects \
  -v ~/Documents:/home/cursoruser/host-documents \
  -v ~/Downloads:/home/cursoruser/host-downloads \
  -v /dev/dri:/dev/dri \
  -v /run/dbus:/run/dbus \
  -v /run/user/$USER_ID/pulse:/run/user/1000/pulse \
  --device /dev/dri \
  --device /dev/fuse \
  --device /dev/snd \
  --cap-add SYS_ADMIN \
  --security-opt apparmor:unconfined \
  cursor-firefox-ppa

# Restrict access when done
xhost -local:

echo "Cursor container has been shut down."