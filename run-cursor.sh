#!/bin/bash

# Create directories for Cursor and browser data if they don't exist
mkdir -p /tmp/cursor-home
mkdir -p /tmp/cursor-config
mkdir -p /tmp/firefox-profile
sudo chown -R 1000:1000 /tmp/cursor-home
sudo chown -R 1000:1000 /tmp/cursor-config
sudo chown -R 1000:1000 /tmp/firefox-profile

# Create projects directory if it doesn't exist
mkdir -p ~/cursor-projects

# First, make sure xhost allows connections from localhost
xhost +local:

# Build the Docker image
echo "Building Cursor container image..."
docker build -t cursor-firefox-ppa -f Dockerfile .

# Get current user ID
USER_ID=$(id -u)

# Run using X11 forwarding with proper directory mounts
echo "Starting Cursor container..."
docker run -it --rm \
  --name cursor-instance \
  --hostname cursor-container \
  --net=host \
  -e DISPLAY=$DISPLAY \
  -e XAUTHORITY=$HOME/.Xauthority \
  -v $HOME/.Xauthority:/home/cursoruser/.Xauthority:ro \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /tmp/cursor-home:/home/cursoruser/.cursor \
  -v /tmp/cursor-config:/home/cursoruser/.config/Cursor \
  -v /tmp/firefox-profile:/home/cursoruser/.mozilla/firefox \
  -v ~/cursor-projects:/home/cursoruser/projects \
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
