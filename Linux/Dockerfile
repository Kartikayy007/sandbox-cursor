FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Combine all apt operations into a single layer with optimized package installation
RUN apt update && \
    # Install in order of likelihood to change (stable packages first)
    apt install -y --no-install-recommends \
    # Core system libraries (rarely change)
    libglib2.0-0 libgtk-3-0 libxkbcommon0 libnss3 libx11-6 \
    libxcomposite1 libxdamage1 libxrandr2 libasound2 libxext6 \
    libxtst6 libatk1.0-0 libatk-bridge2.0-0 libcups2 libgbm1 \
    libwayland-client0 libwayland-cursor0 libwayland-egl1 \
    libwayland-server0 libdrm2 libdbus-1-3 \
    # System utilities
    wget ca-certificates fuse xdg-utils mesa-utils dbus-x11 \
    xvfb x11-xserver-utils pulseaudio locales \
    software-properties-common gnupg curl sudo \
    # Development tools (more likely to change versions)
    git python3 python3-pip python3-venv \
    # Optional tools (comment out if not needed to save space and time)
    vim nano htop zip unzip \
    && \
    # Install Firefox in same layer to avoid extra apt update
    add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001' > /etc/apt/preferences.d/mozilla-firefox && \
    apt update && apt install -y --no-install-recommends firefox && \
    # Install Node.js from NodeSource for latest stable version
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && \
    apt install -y nodejs && \
    # Update npm to latest version
    npm install -g npm@latest && \
    # Cleanup in same layer to reduce image size
    apt-get autoremove -y && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get clean

# Set up locale in a single optimized layer
RUN locale-gen en_US.UTF-8 && \
    # Create user with dynamic UID (will be overridden by run script if needed)
    useradd -u 1000 -ms /bin/bash cursoruser && \
    usermod -aG sudo cursoruser && \
    echo "cursoruser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/cursoruser && \
    chmod 0440 /etc/sudoers.d/cursoruser && \
    # Create all directories at once with proper permissions
    mkdir -p /home/cursoruser/.cursor/extensions \
             /home/cursoruser/.config/Cursor/Code\ Cache/js \
             /home/cursoruser/.config/Cursor/Code\ Cache/wasm \
             /home/cursoruser/.config/Cursor/User/globalStorage \
             /home/cursoruser/.mozilla/firefox \
             /home/cursoruser/projects \
             /home/cursoruser/host-documents \
             /home/cursoruser/host-downloads && \
    chown -R cursoruser:cursoruser /home/cursoruser && \
    chmod -R 755 /home/cursoruser/.cursor /home/cursoruser/.config

# Set environment variables
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    BROWSER="/usr/bin/firefox" \
    ELECTRON_DEFAULT_ERROR_MODE=1 \
    ELECTRON_ENABLE_LOGGING=1

# Set work directory and switch to user
USER cursoruser
WORKDIR /home/cursoruser

# Setup shell and copy AppImage in optimized way
# Copy all AppImage files and create a script to find the right one
COPY --chown=cursoruser:cursoruser *.AppImage ./
RUN chmod +x *.AppImage && \
    # Create a script to find and use the Cursor AppImage
    echo '#!/bin/bash\n\
# Find the Cursor AppImage automatically\n\
CURSOR_APPIMAGE=$(find /home/cursoruser -name "*.AppImage" -type f | head -1)\n\
\n\
if [ -z "$CURSOR_APPIMAGE" ]; then\n\
    echo "Error: No AppImage found in /home/cursoruser/"\n\
    echo "Please make sure you have downloaded the Cursor AppImage"\n\
    exit 1\n\
fi\n\
\n\
echo "Found Cursor AppImage: $(basename $CURSOR_APPIMAGE)"\n\
\n\
# Enhanced permission fixes for cross-system compatibility\n\
echo "Setting up container permissions..."\n\
\n\
# Fix ownership of mounted volumes if they exist and have wrong permissions\n\
[ -d "/home/cursoruser/projects" ] && sudo chown -R cursoruser:cursoruser /home/cursoruser/projects\n\
[ -d "/home/cursoruser/host-documents" ] && sudo chown -R cursoruser:cursoruser /home/cursoruser/host-documents\n\
[ -d "/home/cursoruser/host-downloads" ] && sudo chown -R cursoruser:cursoruser /home/cursoruser/host-downloads\n\
\n\
# Ensure configuration directories have correct permissions\n\
sudo chown -R cursoruser:cursoruser /home/cursoruser/.cursor /home/cursoruser/.config/Cursor /home/cursoruser/.mozilla\n\
sudo chmod -R 755 /home/cursoruser/.cursor /home/cursoruser/.config/Cursor\n\
\n\
# Set proper permissions for mounted directories\n\
[ -d "/home/cursoruser/projects" ] && chmod 755 /home/cursoruser/projects\n\
[ -d "/home/cursoruser/host-documents" ] && chmod 755 /home/cursoruser/host-documents\n\
[ -d "/home/cursoruser/host-downloads" ] && chmod 755 /home/cursoruser/host-downloads\n\
\n\
echo "Starting Cursor..."\n\
exec "$CURSOR_APPIMAGE" --no-sandbox' > start-cursor.sh && \
    chmod +x start-cursor.sh && \
    # Setup custom prompt
    echo 'export PS1="\[\033[01;32m\]\u@cursor-container\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> .bashrc

# Default command - use our wrapper script
CMD ["./start-cursor.sh"]