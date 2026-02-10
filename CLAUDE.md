# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker containerization for [anytype-cli](https://github.com/anyproto/anytype-cli), wrapping the Anytype HTTP API server with automatic credential initialization.

## Key Architecture Concepts

**Auto-initialization Flow:**
The entrypoint script (`entrypoint.sh`) implements a complex initialization sequence:
1. Checks if credentials exist at `.anytype/credentials.json`
2. If missing: starts `anytype serve` in background → waits for gRPC port 31010 → runs `anytype auth create` → kills server → restarts in foreground
3. If present: starts server normally with `exec`

**Why this complexity:**
- `anytype auth create` requires a running gRPC server (port 31010)
- The server must restart after credential creation to properly initialize the HTTP API
- `tini` (PID 1) ensures proper signal handling (SIGTERM/SIGINT forwarding)
- Using `exec` in final server start ensures signals go directly to the process

**Port Mapping Strategy:**
- Container internally uses 31012 for HTTP API
- Externally mapped to 31009 for compatibility with anytype-mcp
- gRPC (31010) and gRPC-Web (31011) ports pass through directly

## Common Commands

### Build and Run
```bash
# Build image
docker compose build

# Start service (auto-initializes on first run)
docker compose up -d

# View logs (check initialization status)
docker compose logs -f anytype

# Restart service (required after manual credential changes)
docker compose restart anytype

# Stop service
docker compose down
```

### Manual Credential Management
```bash
# Create credentials manually (if ANYTYPE_BOT_NAME not set)
docker compose exec anytype anytype auth create <name>
docker compose restart anytype  # Required after manual creation
```

### Debugging
```bash
# Shell access
docker compose exec anytype sh

# Check if gRPC server is running
docker compose exec anytype nc -z localhost 31010

# View environment
docker compose exec anytype env
```

## Critical Files

- **`Dockerfile`**: Multi-stage Alpine build, uses official install script
- **`entrypoint.sh`**: Orchestrates initialization and server lifecycle
- **`docker-compose.yaml`**: Defines port mappings, environment, and volumes
- **`install.sh`**: Official anytype-cli installation script (copied during build)

## Important Details

- Credentials persist in `.anytype` volume (mounted from host directory)
- Auto-init only runs once when credentials are missing
- Server runs as non-root user `anytype` (UID created in Dockerfile)
- Changes to `entrypoint.sh` require image rebuild (`docker compose build`)
- Changes to environment variables require container restart (`docker compose up -d`)
