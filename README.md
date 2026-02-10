# anytype-docker

Docker setup around [anytype-cli](https://github.com/anyproto/anytype-cli)

The primary intended use would be to connect an anytype bot account to your space. Then you can use the api to act as the bot account on your space.

## Quickstart

1. **Configure environment variables** in `docker-compose.yaml`:
   ```yaml
   environment:
     ANYTYPE_BOT_NAME: my-anytype-bot  # Bot account name (auto-created on first run)
     ANYTYPE_LOG_LEVEL: INFO           # Logging level (DEBUG, INFO, WARN, ERROR)
     ANYTYPE_LISTEN_ADDRESS: 0.0.0.0:31009  # HTTP API bind address
     DATA_PATH: /home/anytype/.anytype/data # Data directory inside container
   ```

2. **Start the service**:
   ```bash
   docker compose up -d
   ```
   On first run, the service auto-creates credentials and starts the Anytype server.

3. **Check status**:
   ```bash
   docker compose ps        # Check if healthy
   docker compose logs -f   # View logs
   ```

**Data Storage:**
- All data (credentials, spaces, objects) persists in the `anytype-data` volume mounted at `/home/anytype`
- Survives container restarts and rebuilds

**Service Endpoints:**
- HTTP API: http://localhost:31009
- gRPC: localhost:31010
- gRPC-Web: localhost:31011

## Creating an API Key

To interact with the HTTP API, create an API key:

```bash
docker compose exec anytype anytype auth api-key create <key-name>
```

Save the generated API key securely. Use it in your requests:
```bash
curl -L http://localhost:31009/v1/spaces \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H 'Accept: application/json'
```

## Joining a Space

Connect your bot account to an Anytype space:

1. **Get an invite link** from your Anytype app (Share → Get Invite Link)

2. **Join the space**:
   ```bash
   docker compose exec anytype anytype space join <invite-link>
   ```

3. **Verify**:
   ```bash
   docker compose exec anytype anytype space list
   ```

## Troubleshooting

### panic: runtime error: invalid memory address or nil pointer dereference

Try removing the docker volume storing the anytype data and starting fresh.
