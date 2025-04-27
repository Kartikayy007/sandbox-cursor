# Cursor in Docker for macOS

This project allows you to run Cursor code editor inside a Docker container on macOS, bypassing trial limitations while maintaining a seamless development experience.

## Overview

This solution:
- Uses Docker to create an isolated Linux environment running Cursor
- Configures XQuartz for display forwarding
- Downloads Cursor directly during the Docker build process
- Mounts your local directories to access files
- Persists Cursor settings with Docker volumes

## Prerequisites

- [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)
- [XQuartz](https://www.xquartz.org/) (for X11 display forwarding)
- Basic familiarity with terminal commands
- Approximately 2GB of free disk space

## Installation Instructions

### 1. Install XQuartz

XQuartz is required for display forwarding:

```bash
brew install --cask xquartz
```

After installation, **restart your computer** to ensure XQuartz is properly configured.

### 2. Configure XQuartz

Open XQuartz, go to Preferences > Security tab and check "Allow connections from network clients"

### 3. Run the Script

```bash
chmod +x run-cursor-macos-fixed.sh
./run-cursor-macos-fixed.sh
```

The first run will:
1. Install XQuartz if needed
2. Pull/build the Docker image
3. Download Cursor directly
4. Set up persistent volumes
5. Launch Cursor

## Troubleshooting

### 1. Registry Connection Issues

If you see errors about failing to pull the Ubuntu image:

```bash
docker pull ubuntu:22.04 --registry-mirror=https://registry-1.docker.io
```

### 2. XQuartz Configuration

Make sure XQuartz is properly configured:

```bash
defaults write org.xquartz.X11 nolisten_tcp 0
defaults write org.xquartz.X11 app_to_run /usr/bin/true
defaults write org.xquartz.X11 enable_iglx -bool true
```

Then restart XQuartz.

### 3. Display Issues

If Cursor doesn't display, check your IP configuration:

```bash
# Find your IP address
ifconfig en0 | grep inet | awk '$1=="inet" {print $2}'
```

Edit the script to manually set this IP if auto-detection fails.

### 4. Container Exiting Immediately

If the container exits immediately:

```bash
# Run in debug mode
docker run -it --rm --entrypoint /bin/bash cursor-firefox-mac
```

Then run `/home/cursoruser/start-cursor.sh` manually to see any errors.

## How It Works

This solution uses:

1. An Ubuntu container with X11 forwarding to XQuartz
2. Direct download of Cursor during container build
3. Firefox for authentication
4. Docker volumes for persistence
5. XQuartz for displaying the GUI

## Advanced Configuration

### Using Custom Cursor Version

If you want to use a specific version of Cursor, edit the Dockerfile.mac file and change the URL in the wget command.

### Manual Container Management

You can manually manage the container:

```bash
# Build the image
docker build -t cursor-firefox-mac -f Dockerfile.mac .

# Run with specific options
docker run -it --rm \
  -e DISPLAY=YOUR_IP:0 \
  -v cursor_app_data_mac:/home/cursoruser/.cursor \
  cursor-firefox-mac
```

### Reset Configuration

To completely reset Cursor's configuration:

```bash
docker volume rm cursor_app_data_mac cursor_config_data_mac firefox_profile_data_mac
```