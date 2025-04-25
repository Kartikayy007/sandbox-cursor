# Cursor in Docker

This project allows you to run Cursor code editor inside a Docker container with proper system integration. It provides a containerized environment for Cursor with Firefox integration, allowing you to bypass Cursor's free trial limitations while maintaining a seamless development experience.

## Overview

This project consists of:
- A Dockerfile that sets up Ubuntu with Cursor and Firefox
- Run scripts for both Linux and Windows
- Volume management for persistent configuration

Using this setup, you can work with Cursor in an isolated environment while still accessing your local files.

## Prerequisites


### For Windows:
- Docker Desktop for Windows installed 
- An X server for Windows (VcXsrv, X410, or MobaXterm)
- Windows PowerShell
- Basic familiarity with Docker and PowerShell commands
- Approximately 2GB of free disk space

## Installation Instructions

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/cursor-docker.git
cd cursor-docker
```

### 2. Download Cursor AppImage

Download the latest Cursor AppImage from the official website:

1. Visit [cursor.sh](https://cursor.sh) and download the Linux AppImage
2. Place the downloaded AppImage in the same directory as the Dockerfile
3. Rename it to `Cursor.AppImage` if needed

### 3. Setup Instructions for windows


#### Windows Setup:

1. **Install an X Server for Windows**
   
   Install one of the following X servers:
   - [VcXsrv](https://sourceforge.net/projects/vcxsrv/) (Free)
   - [X410](https://x410.dev/) (Paid, available on Microsoft Store)
   - [MobaXterm](https://mobaxterm.mobatek.net/) (Free personal edition)

2. **Configure your X Server**
   
   For VcXsrv (XLaunch):
   - Start XLaunch
   - Choose "Multiple windows" and set display number to 0
   - In the next screen, select "Start no client"
   - In "Extra settings", check:
     - "Disable access control"
     - "Native opengl"
   - Finish the wizard to start the X server

3. **Run the Windows PowerShell script**
   
   Right-click on `run-cursor-windows.ps1` and select "Run with PowerShell", or open PowerShell and run:

   ```powershell
   .\run-cursor-windows.ps1
   ```

4. **First-time setup**
   
   The first run will take some time as it builds the Docker image.

## Usage

After running the script, Cursor will open within the Docker container. Your projects will be saved to the `~/cursor-projects` directory on Linux or `%USERPROFILE%\cursor-projects` on Windows.

The container mounts the following directories:
- `cursor-projects`: Main workspace for your code
- `Documents`: Accessible as `/home/cursoruser/host-documents`
- `Downloads`: Accessible as `/home/cursoruser/host-downloads`

Application data is stored in Docker volumes:
- `cursor_app_data`: Cursor application data
- `cursor_config_data`: Cursor configuration
- `firefox_profile_data`: Firefox profile data

## Troubleshooting

### Windows Issues

#### X Server not connected

If Cursor doesn't display, check that:
- Your X server is running
- You've enabled "Disable access control" in X server settings
- Try restarting Docker Desktop
- Ensure Windows Defender Firewall isn't blocking the X server

#### Could not connect to display

If you see errors about not being able to connect to the display:

1. Check your X server is running
2. Try running this command in PowerShell to verify the host:
   ```powershell
   ipconfig
   ```
3. Look for the Docker network adapter IP and try using that in the `-e DISPLAY` parameter

#### Firefox not launching

Firefox is configured to launch on-demand when Cursor needs it for authentication. If Firefox doesn't start, you can manually launch it from within the container:

```bash
firefox --new-instance
```

## Windows-Specific X Server Tips

### Using VcXsrv (XLaunch)

- Always start XLaunch before running the Cursor container
- Create a shortcut to XLaunch in your startup folder with your preferred configuration
- You can save your XLaunch configuration to a `.xlaunch` file for quick startup

### Using X410

- Enable "Public Mode" in X410 settings
- Turn on "Allow Public Access" 
- Add a Windows Defender Firewall exception for X410

### Using MobaXterm

- In the MobaXterm settings, go to X11 tab
- Check "X11 Remote Access" 
- Set "X11 port" to 6000

## How It Works

This solution uses:

1. Docker containers for isolation
2. X11 forwarding for displaying GUI applications
3. Volume mounting for file persistence
4. Firefox integration for authentication
5. Named Docker volumes for application data

The Cursor AppImage runs inside the container while Firefox handles any authentication needs. Files are saved directly to your host system through mounted volumes.

## Technical Details

### Windows Implementation

On Windows, Docker cannot directly access the host's display system. Instead:

1. An X server runs on Windows (VcXsrv, X410, etc.)
2. The Docker container connects to this X server using the host.docker.internal DNS name
3. The X server renders the application window on Windows

This additional layer adds some complexity but allows the Linux-based Docker container to display GUI applications on Windows.