# Cursor in Docker

This project allows you to run Cursor code editor inside a Docker container with proper system integration. It provides a containerized environment for Cursor with Firefox integration, allowing you to bypass Cursor's free trial limitations while maintaining a seamless development experience.

## Overview

This project consists of:
- A Dockerfile that sets up Ubuntu with Cursor and Firefox
- A run script that properly mounts volumes and handles display forwarding
- Volume management for persistent configuration

Using this setup, you can work with Cursor in an isolated environment while still accessing your local files.

## Prerequisites

- Docker installed on your Linux system
- X11 display server running
- Basic familiarity with Docker and terminal commands
- Approximately 2GB of free disk space

## Installation Instructions

### 1. Clone the repository

```bash
git clone https://github.com/iiviie/sandbox-cursor.git
cd sandbox-cursor
```

### 2. Download Cursor AppImage

Download the latest Cursor AppImage from the official website:

1. Visit [cursor.sh](https://cursor.sh) and download the Linux AppImage
2. Place the downloaded AppImage in the same directory as the Dockerfile
3. Rename it to `Cursor.AppImage` if needed

### 3. Build and run the container

Make the run script executable:

```bash
chmod +x run-cursor.sh
```

Run the script:

```bash
./run-cursor.sh
```

The first run will take some time as it builds the Docker image.

## Usage

After running the script, Cursor will open within the Docker container. Your projects will be saved to the `~/cursor-projects` directory on your host machine.

The container mounts the following directories:
- `~/cursor-projects`: Main workspace for your code
- `~/Documents`: Accessible as `/home/cursoruser/host-documents`
- `~/Downloads`: Accessible as `/home/cursoruser/host-downloads`

Application data is stored in Docker volumes:
- `cursor_app_data`: Cursor application data
- `cursor_config_data`: Cursor configuration
- `firefox_profile_data`: Firefox profile data

## Troubleshooting

### Permission issues

If you encounter permission errors when starting Cursor, try uncommenting the permissions fix section in the `run-cursor.sh` script.

### Display issues

If you have problems with X11 forwarding, ensure you've allowed connections:

```bash
xhost +local:
```

### Firefox not launching

Firefox is configured to launch on-demand when Cursor needs it for authentication. If Firefox doesn't start, you can manually launch it from within the container:

```bash
firefox --new-instance
```

## How It Works

This solution uses:

1. Docker containers for isolation
2. X11 forwarding for displaying GUI applications
3. Volume mounting for file persistence
4. Firefox integration for authentication
5. Named Docker volumes for application data

The Cursor AppImage runs inside the container while Firefox handles any authentication needs. Files are saved directly to your host system through mounted volumes.