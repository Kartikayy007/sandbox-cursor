# Sandboxed Cursor Editor

This project provides a containerized solution for running the Cursor code editor in an isolated environment while maintaining system integration. It allows you to bypass Cursor's free trial limitations while keeping your development environment secure and organized.

## Overview

The Sandboxed Cursor Editor project enables you to run Cursor inside a Docker container with proper system integration, including:
- Seamless file system access
- Display forwarding
- Firefox integration for authentication
- Persistent configuration and data storage

## Platform-Specific Instructions

Choose your operating system for detailed setup instructions:

- [Linux Installation Guide](Linux/linux-readme.md)
- [MacOS Installation Guide](MacOS/readme.md)
- [Windows Installation Guide](Windows/windows-readme.md)


## Key Features

- **Isolated Environment**: Run Cursor in a Docker container for better security and system isolation
- **System Integration**: Access your local files and directories seamlessly
- **Persistent Storage**: Your projects and configurations are saved between sessions
- **Cross-Platform**: Available for Linux and MacOS (Windows support coming soon)
- **Firefox Integration**: Built-in support for authentication and web access

## Prerequisites

- Docker installed on your system
- Basic familiarity with terminal commands
- Approximately 2GB of free disk space
- Platform-specific requirements (see platform guides above)

## Project Structure

```
sandboxed-cursor/
├── Linux/
│   ├── linux-readme.md
│   ├── Dockerfile
│   └── run-cursor.sh
├── MacOS/
│   ├── readme.md
│   └── [MacOS specific files]
├── Windows/
│   ├── windows-readme.md
│   ├── Dockerfile
│   └── run-cursor-windows.ps1
└── readme.md
```
