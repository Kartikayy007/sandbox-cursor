#!/bin/bash

# Create projects directory if it doesn't exist
mkdir -p ~/cursor-projects

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running. Please start Docker Desktop and try again."
  exit 1
fi

# Check if XQuartz is installed
if ! command -v xquartz &> /dev/null; then
    echo "XQuartz is not installed. Please install it first:"
    echo "brew install --cask xquartz"
    echo "Then restart your computer before running this script again."
    exit 1
fi

# Start XQuartz if not already running
if ! pgrep -x "Xquartz" > /dev/null; then
    echo "Starting XQuartz..."
    open -a XQuartz
    # Wait for XQuartz to start
    sleep 5
fi

# Allow connections from localhost to XQuartz
xhost +localhost

# Attempt to pull the image directly to address registry issues
echo "Pulling Ubuntu image..."
docker pull ubuntu:22.04 || echo "Warning: Unable to pull Ubuntu image, continuing with build..."

# Build the Docker image
echo "Building Cursor container image..."
docker build -t cursor-firefox-mac -f Dockerfile.mac .

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "Build failed. Trying with alternative approach..."
    # If the build failed, try to use a local image
    echo "FROM ubuntu:latest" > Dockerfile.mac.alt
    cat Dockerfile.mac | tail -n +2 >> Dockerfile.mac.alt
    docker build -t cursor-firefox-mac -f Dockerfile.mac.alt .
    
    if [ $? -ne 0 ]; then
        echo "Alternative build also failed. Please check Docker configuration."
        exit 1
    fi
fi

# Initialize Docker volumes
echo "Setting up Docker volumes..."
docker volume create cursor_app_data_mac
docker volume create cursor_config_data_mac
docker volume create firefox_profile_data_mac

# Get IP address for display forwarding
IP=$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}')
if [ -z "$IP" ]; then
    # Try alternative interface if en0 doesn't work
    IP=$(ifconfig en1 | grep inet | awk '$1=="inet" {print $2}')
fi

if [ -z "$IP" ]; then
    echo "Could not determine IP address. Please check your network connection."
    exit 1
fi

echo "Using IP address: $IP for display forwarding"

# Make sure XQuartz allows connections from Docker
defaults write org.xquartz.X11 nolisten_tcp 0
defaults write org.xquartz.X11 app_to_run /usr/bin/true
defaults write org.xquartz.X11 enable_iglx -bool true

# Restart XQuartz if needed
killall Xquartz 2>/dev/null || true
open -a XQuartz
sleep 3
xhost + $IP

# Run using XQuartz display forwarding with proper volume mounts
echo "Starting Cursor container..."
docker run -it --rm \
  --name cursor-instance-mac \
  --hostname cursor-container-mac \
  -e DISPLAY=$IP:0 \
  -v cursor_app_data_mac:/home/cursoruser/.cursor \
  -v cursor_config_data_mac:/home/cursoruser/.config/Cursor \
  -v firefox_profile_data_mac:/home/cursoruser/.mozilla/firefox \
  -v ~/cursor-projects:/home/cursoruser/projects \
  -v ~/Documents:/home/cursoruser/host-documents \
  -v ~/Downloads:/home/cursoruser/host-downloads \
  --cap-add SYS_ADMIN \
  cursor-firefox-mac

# Restrict access when done
xhost -localhost

echo "Cursor container has been shut down."