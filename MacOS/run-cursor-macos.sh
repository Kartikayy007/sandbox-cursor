#!/bin/bash

# Create projects directory if it doesn't exist
mkdir -p ~/cursor-projects

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running. Please start Docker Desktop and try again."
  exit 1
fi

# Check if Cursor.AppImage exists
if [ ! -f "Cursor.AppImage" ]; then
  echo "Cursor.AppImage not found in the current directory."
  echo "Please download Cursor AppImage from https://cursor.sh/"
  echo "and place it in the same directory as this script."
  exit 1
fi

# Check if XQuartz is installed
if ! [ -d "/Applications/Utilities/XQuartz.app" ]; then
    echo "XQuartz is not installed. Please install it first:"
    echo "brew install --cask xquartz"
    echo "Then restart your computer before running this script again."
    exit 1
fi

# Start XQuartz using open command
echo "Starting XQuartz..."
open -a XQuartz
# Wait for XQuartz to start
sleep 3

# Configure XQuartz to allow connections
echo "Configuring XQuartz..."
defaults write org.xquartz.X11 nolisten_tcp 0
defaults write org.xquartz.X11 app_to_run /usr/bin/true
defaults write org.xquartz.X11 enable_iglx -bool true

# Check if XQuartz is running
if ! pgrep -x "XQuartz" > /dev/null; then
    echo "XQuartz failed to start. Please start it manually and try again."
    exit 1
fi

# Allow connections from localhost to XQuartz
xhost +localhost

# Build the Docker image
echo "Building Cursor container image..."
docker build -t cursor-firefox-mac -f Dockerfile.mac .

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "Build failed. Please check the errors above."
    exit 1
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
    # Last resort, try localhost
    IP="127.0.0.1"
    echo "Could not determine network IP address, using localhost (127.0.0.1)"
else
    echo "Using IP address: $IP for display forwarding"
fi

# Make sure XQuartz allows connections from Docker
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