#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to script directory so we can find the AppImage and Dockerfile
cd "$SCRIPT_DIR"

# Optimization: Create projects directory if it doesn't exist
mkdir -p ~/cursor-projects

# Check for Cursor AppImage before building
check_appimage() {
    local appimage_count=$(find "$SCRIPT_DIR" -maxdepth 1 -name "*.AppImage" -type f | wc -l)
    
    if [ $appimage_count -eq 0 ]; then
        echo "❌ Error: No AppImage file found in the script directory!"
        echo ""
        echo "📥 Please download the Cursor AppImage:"
        echo "   1. Visit https://cursor.sh"
        echo "   2. Download the Linux AppImage"
        echo "   3. Place it in: $SCRIPT_DIR"
        echo ""
        echo "Expected file: cursor-*.AppImage or Cursor*.AppImage"
        exit 1
    elif [ $appimage_count -gt 1 ]; then
        echo "⚠️  Warning: Multiple AppImage files found in $SCRIPT_DIR:"
        find "$SCRIPT_DIR" -maxdepth 1 -name "*.AppImage" -type f -exec basename {} \;
        echo ""
        echo "🎯 The build will use the first one found. If this is not intended,"
        echo "   please remove the extra AppImage files and keep only the Cursor one."
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        local appimage_file=$(find "$SCRIPT_DIR" -maxdepth 1 -name "*.AppImage" -type f | head -1)
        echo "✅ Found AppImage: $(basename "$appimage_file")"
    fi
}

# Optimization: Check if image already exists to skip unnecessary builds
check_image_exists() {
    docker image inspect cursor-firefox-ppa >/dev/null 2>&1
}

# Optimization: Create volumes only if they don't exist
setup_volumes() {
    echo "Setting up Docker volumes..."
    docker volume inspect cursor_app_data >/dev/null 2>&1 || docker volume create cursor_app_data
    docker volume inspect cursor_config_data >/dev/null 2>&1 || docker volume create cursor_config_data  
    docker volume inspect firefox_profile_data >/dev/null 2>&1 || docker volume create firefox_profile_data
}

# Function to detect display server and setup appropriate forwarding
detect_display_server() {
    if [ -n "$WAYLAND_DISPLAY" ] && [ -n "$XDG_RUNTIME_DIR" ]; then
        echo "wayland"
    elif [ -n "$DISPLAY" ]; then
        echo "x11"
    else
        echo "unknown"
    fi
}

# Function to setup display forwarding based on detected server
setup_display_forwarding() {
    local display_server=$(detect_display_server)
    
    echo "Detected display server: $display_server"
    
    case $display_server in
        "wayland")
            setup_wayland_forwarding
            ;;
        "x11")
            setup_x11_forwarding
            ;;
        "unknown")
            echo "Warning: Could not detect display server"
            echo "Trying X11 as fallback..."
            setup_x11_forwarding
            ;;
    esac
}

# Function to setup Wayland forwarding
setup_wayland_forwarding() {
    echo "Setting up Wayland forwarding..."
    
    # Check if Wayland socket exists
    local wayland_socket="$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
    if [ ! -S "$wayland_socket" ]; then
        echo "Warning: Wayland socket not found at $wayland_socket"
        echo "Falling back to X11 via XWayland..."
        setup_x11_forwarding
        return 1
    fi
    
    # Set Wayland-specific environment variables
    export DISPLAY_MODE="wayland"
    export WAYLAND_SOCKET_PATH="$wayland_socket"
    
    echo "Wayland setup complete"
    return 0
}

# Function to setup X11 forwarding
setup_x11_forwarding() {
    echo "Setting up X11 forwarding..."
    
    # Check if DISPLAY is set
    if [ -z "$DISPLAY" ]; then
        echo "Warning: DISPLAY environment variable is not set"
        echo "Display forwarding may not work properly"
        return 1
    fi
    
    # Check if X11 socket exists
    if [ ! -d "/tmp/.X11-unix" ]; then
        echo "Warning: X11 socket directory not found"
        echo "Make sure X11 or XWayland is running on the host"
        return 1
    fi
    
    export DISPLAY_MODE="x11"
    echo "X11 setup complete - using simple host network method"
    return 0
}

# Function to cleanup - mostly a placeholder for consistency
cleanup_display_forwarding() {
    echo "Display forwarding cleanup complete"
}

# Set up display forwarding (auto-detect X11 vs Wayland)
setup_display_forwarding

# Check for AppImage before proceeding
check_appimage

# Optimization: Only build if image doesn't exist or if forced
if ! check_image_exists; then
    echo "Building Cursor container image..."
    docker build -t cursor-firefox-ppa -f Dockerfile .
else
    echo "Using existing Cursor container image (use 'docker rmi cursor-firefox-ppa' to force rebuild)"
fi

# Get current user ID and group ID for proper permission mapping
USER_ID=$(id -u)
GROUP_ID=$(id -g)

echo "Using UID: $USER_ID, GID: $GROUP_ID"

# Setup volumes efficiently
setup_volumes

# Create host directories if they don't exist and set proper permissions
echo "Setting up host directories with proper permissions..."
mkdir -p ~/cursor-projects ~/Documents ~/Downloads
# Ensure the directories are accessible
chmod 755 ~/cursor-projects ~/Documents ~/Downloads 2>/dev/null || true

# Prepare Hyprland arguments if needed
HYPRLAND_ARGS=""
if command -v hyprctl &> /dev/null && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    echo "Detected Hyprland, adding Hyprland-specific variables..."
    HYPRLAND_ARGS="-e HYPRLAND_INSTANCE_SIGNATURE=$HYPRLAND_INSTANCE_SIGNATURE -v /tmp/hypr:/tmp/hypr"
fi

# Build and run Docker command based on display mode
echo "Starting Cursor container..."
if [ "$DISPLAY_MODE" = "wayland" ]; then
    # Wayland mode with proper argument handling
    docker run -it --rm \
      --name cursor-instance \
      --hostname cursor-container \
      --add-host cursor-container:127.0.0.1 \
      --net=host \
      --user "$USER_ID:$GROUP_ID" \
      -e WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
      -e XDG_RUNTIME_DIR=/tmp/xdg-runtime \
      -v "$XDG_RUNTIME_DIR":/tmp/xdg-runtime \
      -e DISPLAY="$DISPLAY" \
      -v /tmp/.X11-unix:/tmp/.X11-unix \
      $HYPRLAND_ARGS \
      -v cursor_app_data:/home/cursoruser/.cursor \
      -v cursor_config_data:/home/cursoruser/.config/Cursor \
      -v firefox_profile_data:/home/cursoruser/.mozilla/firefox \
      -v ~/cursor-projects:/home/cursoruser/projects:rw \
      -v ~/Documents:/home/cursoruser/host-documents:rw \
      -v ~/Downloads:/home/cursoruser/host-downloads:rw \
      -v /dev/dri:/dev/dri \
      -v /run/dbus:/run/dbus \
      -v /run/user/$USER_ID/pulse:/run/user/1000/pulse \
      --device /dev/dri \
      --device /dev/fuse \
      --device /dev/snd \
      --cap-add SYS_ADMIN \
      --security-opt apparmor:unconfined \
      cursor-firefox-ppa
else
    # X11 mode
    docker run -it --rm \
      --name cursor-instance \
      --hostname cursor-container \
      --add-host cursor-container:127.0.0.1 \
      --net=host \
      --user "$USER_ID:$GROUP_ID" \
      -e DISPLAY="$DISPLAY" \
      -v /tmp/.X11-unix:/tmp/.X11-unix \
      -v cursor_app_data:/home/cursoruser/.cursor \
      -v cursor_config_data:/home/cursoruser/.config/Cursor \
      -v firefox_profile_data:/home/cursoruser/.mozilla/firefox \
      -v ~/cursor-projects:/home/cursoruser/projects:rw \
      -v ~/Documents:/home/cursoruser/host-documents:rw \
      -v ~/Downloads:/home/cursoruser/host-downloads:rw \
      -v /dev/dri:/dev/dri \
      -v /run/dbus:/run/dbus \
      -v /run/user/$USER_ID/pulse:/run/user/1000/pulse \
      --device /dev/dri \
      --device /dev/fuse \
      --device /dev/snd \
      --cap-add SYS_ADMIN \
      --security-opt apparmor:unconfined \
      cursor-firefox-ppa
fi

# Note: Cleanup is handled by Docker's --rm flag
echo "Cursor container has been shut down."