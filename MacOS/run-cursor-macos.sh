#!/bin/bash

# Create projects directory if it doesn't exist
mkdir -p ~/cursor-projects

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

# Build the Docker image
echo "Building Cursor container image..."
docker build -t cursor-firefox-mac -f Dockerfile.mac .

# Get current user ID
USER_ID=$(id -u)

# Initialize Docker volumes with correct permissions if they don't exist
echo "Setting up Docker volumes with correct permissions..."
docker volume create cursor_app_data_mac
docker volume create cursor_config_data_mac
docker volume create firefox_profile_data_mac

# Optional: Run a one-time permissions fix on existing volumes
# Uncomment this section if you're having permission issues
# docker run --rm -it \
#   -v cursor_app_data_mac:/cursor_app_data \
#   -v cursor_config_data_mac:/cursor_config_data \
#   -v firefox_profile_data_mac:/firefox_profile_data \
#   ubuntu:22.04 \
#   /bin/bash -c "mkdir -p /cursor_app_data/extensions && chmod -R 777 /cursor_app_data && chmod -R 777 /cursor_config_data && chmod -R 777 /firefox_profile_data"

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
  --device /dev/fuse \
  --cap-add SYS_ADMIN \
  --security-opt apparmor:unconfined \
  cursor-firefox-mac

# Restrict access when done
xhost -localhost

echo "Cursor container has been shut down."