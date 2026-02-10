# anytype-docker

Docker setup around [anytype-cli](https://github.com/anyproto/anytype-cli)

## Architecture

**Auto-initialization flow:**
1. Container starts with `tini` as PID 1 for proper signal handling
2. Entrypoint script checks if credentials exist in `.anytype/credentials.json`
3. If missing: starts server in background → waits for gRPC port 31010 → runs `anytype auth create` → kills server → restarts in foreground
4. If present: starts server normally

**Why this approach:**
- `anytype serve` must be running for `auth create` to work (uses gRPC)
- Server must restart after credential creation to initialize HTTP API
- `tini` ensures signals (SIGTERM, SIGINT) are properly forwarded

## Key Files

- `Dockerfile`: Multi-stage build using official install script
- `entrypoint.sh`: Handles auto-init and server lifecycle
- `docker-compose.yaml`: Port mappings and environment config

## Configuration

**Environment variables:**
- `ANYTYPE_BOT_NAME`: Bot account name for auto-init (default: `anytype-bot`)
- `ANYTYPE_LISTEN_ADDRESS`: HTTP API bind address (default: `0.0.0.0:31012`)
- `ANYTYPE_LOG_LEVEL`: Logging level (default: `INFO`)
- `DATA_PATH`: Data directory (default: `/anytype`)

**Ports:**
- 31010: gRPC server
- 31011: gRPC-Web server
- 31012: HTTP API (mapped to 31009 for anytype-mcp compatibility)

**Volumes:**
- `.anytype`: Credentials storage (persists auth tokens)
- `anytype-data`: Application data

## Usage

```bash
# First run - auto-creates credentials
docker compose up -d

# Check initialization
docker compose logs anytype

# Manual credential creation (if ANYTYPE_BOT_NAME not set)
docker compose exec anytype anytype auth create <name>
docker compose restart anytype
```

## Notes

- Credentials persist across restarts in `.anytype` volume
- Auto-init only runs once on first start
- Server runs as non-root user `anytype`
