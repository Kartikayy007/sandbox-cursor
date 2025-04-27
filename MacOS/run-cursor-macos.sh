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

# Check if socat is installed
if ! command -v socat &> /dev/null; then
    echo "socat is not installed. Installing with Homebrew..."
    brew install socat
fi

# Ask user to start XQuartz manually
echo "Please start XQuartz manually before continuing."
echo "You can do this by opening /Applications/Utilities/XQuartz.app"
echo "Then in XQuartz preferences → Security tab, check 'Allow connections from network clients'"
echo "Press Enter once XQuartz is running and configured..."
read -p ""

# Check if XQuartz is running
if ! pgrep -x "Xquartz" > /dev/null && ! pgrep -x "X11" > /dev/null; then
    echo "XQuartz doesn't appear to be running. Please make sure it's running and try again."
    exit 1
fi

# Configure XQuartz to allow connections
echo "Configuring XQuartz..."
defaults write org.xquartz.X11 nolisten_tcp 0
defaults write org.xquartz.X11 app_to_run /usr/bin/true
defaults write org.xquartz.X11 enable_iglx -bool true

# Allow connections to X server
xhost + 2>/dev/null || echo "Warning: xhost command failed. XQuartz may not be configured correctly."

# Kill any existing socat processes
pkill -f "socat TCP-LISTEN:6000" &>/dev/null || true

# Set up socat to forward X11 traffic
echo "Setting up X11 forwarding via socat..."
socat TCP-LISTEN:6000,reuseaddr,fork UNIX-CLIENT:\"$DISPLAY\" &
SOCAT_PID=$!

# Ensure socat is killed when the script exits
trap "kill $SOCAT_PID 2>/dev/null || true; xhost - 2>/dev/null || true; echo 'Cleaned up X11 forwarding.'" EXIT

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

# Run using socat for display forwarding
echo "Starting Cursor container..."
docker run -it --rm \
  --name cursor-instance-mac \
  --hostname cursor-container-mac \
  -e DISPLAY=host.docker.internal:0 \
  -v cursor_app_data_mac:/home/cursoruser/.cursor \
  -v cursor_config_data_mac:/home/cursoruser/.config/Cursor \
  -v firefox_profile_data_mac:/home/cursoruser/.mozilla/firefox \
  -v ~/cursor-projects:/home/cursoruser/projects \
  -v ~/Documents:/home/cursoruser/host-documents \
  -v ~/Downloads:/home/cursoruser/host-downloads \
  --cap-add SYS_ADMIN \
  cursor-firefox-mac

echo "Cursor container has been shut down."