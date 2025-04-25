# PowerShell script to run Cursor in Docker on Windows

# Create projects directory if it doesn't exist
$cursorProjectsPath = "$env:USERPROFILE\cursor-projects"
if (-not (Test-Path $cursorProjectsPath)) {
    New-Item -ItemType Directory -Path $cursorProjectsPath | Out-Null
    Write-Host "Created directory: $cursorProjectsPath"
}

# Build the Docker image
Write-Host "Building Cursor container image..."
docker build -t cursor-firefox-ppa -f Dockerfile .

# Get current username for display setup
$USERNAME = $env:USERNAME

# Run Docker container with proper volume mounts and X server connection
Write-Host "Starting Cursor container..."
docker run -it --rm `
    --name cursor-instance `
    --hostname cursor-container `
    -e DISPLAY=host.docker.internal:0 `
    -v cursor_app_data:/home/cursoruser/.cursor `
    -v cursor_config_data:/home/cursoruser/.config/Cursor `
    -v firefox_profile_data:/home/cursoruser/.mozilla/firefox `
    -v ${cursorProjectsPath}:/home/cursoruser/projects `
    -v "$env:USERPROFILE\Documents:/home/cursoruser/host-documents" `
    -v "$env:USERPROFILE\Downloads:/home/cursoruser/host-downloads" `
    cursor-firefox-ppa

Write-Host "Cursor container has been shut down."