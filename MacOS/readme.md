# Cursor in Docker for macOS

This project allows you to run Cursor code editor inside a Docker container on macOS with proper system integration. It provides a containerized environment for Cursor with Firefox integration, allowing you to bypass Cursor's free trial limitations while maintaining a seamless development experience.

## Overview

This project consists of:
- A Dockerfile.mac that sets up Ubuntu with Cursor and Firefox
- A run script specifically for macOS that properly mounts volumes and handles display forwarding via XQuartz
- Volume management for persistent configuration

Using this setup, you can work with Cursor in an isolated environment while still accessing your local files.

## Prerequisites

- Docker Desktop installed on your macOS system
- XQuartz installed (for X11 display forwarding)
- Basic familiarity with Docker and terminal commands
- Approximately 2GB of free disk space

## Installation Instructions

### 1. Install XQuartz

XQuartz is required for display forwarding from Docker to macOS:

```bash
brew install --cask xquartz
```

After installation, restart your computer to ensure XQuartz is properly configured.

### 2. Download Cursor AppImage

Download the latest Cursor AppImage from the official website:

1. Visit [cursor.sh](https://cursor.sh) and download the Linux AppImage (yes, the Linux version)
2. Place the downloaded AppImage in the same directory as the Dockerfile.mac
3. Rename it to `Cursor.AppImage` if needed

### 3. Build and run the container

Make the run script executable:

```bash
chmod +x run-cursor-macos.sh
```

Run the script:

```bash
./run-cursor-macos.sh
```

The first run will take some time as it builds the Docker image.

## Usage

After running the script, Cursor will open within the Docker container. Your projects will be saved to the `~/cursor-projects` directory on your host machine.

The container mounts the following directories:
- `~/cursor-projects`: Main workspace for your code
- `~/Documents`: Accessible as `/home/cursoruser/host-documents`
- `~/Downloads`: Accessible as `/home/cursoruser/host-downloads`

Application data is stored in Docker volumes:
- `cursor_app_data_mac`: Cursor application data
- `cursor_config_data_mac`: Cursor configuration
- `firefox_profile_data_mac`: Firefox profile data

## Troubleshooting

### Permission issues

If you encounter permission errors when starting Cursor, try uncommenting the permissions fix section in the `run-cursor-macos.sh` script.

### Display issues

If Cursor does not display:
1. Make sure XQuartz is running
2. Check XQuartz security settings: In XQuartz preferences, go to the Security tab and ensure "Allow connections from network clients" is checked
3. Restart XQuartz and try again

You can manually allow connections with:

```bash
xhost +localhost
```

### Firefox not launching

Firefox is configured to launch on-demand when Cursor needs it for authentication. If Firefox doesn't start, you can manually launch it from within the container:

```bash
/usr/bin/firefox --new-instance
```

### Network issues

If you encounter network issues, check that your IP address is being correctly detected in the script. You may need to modify the IP detection logic if you're using an unusual network configuration.

## How It Works

This solution uses:

1. Docker containers for isolation
2. XQuartz for displaying GUI applications from Docker
3. Volume mounting for file persistence
4. Firefox integration for authentication
5. Named Docker volumes for application data

The Cursor AppImage runs inside the container while Firefox handles authentication. Files are saved directly to your host system through mounted volumes.