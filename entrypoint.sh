#!/bin/sh
set -e

# Set environment variables
CREDS_FILE="/home/anytype/.anytype/config.json"
BOT_NAME="${ANYTYPE_BOT_NAME:-anytype-bot}"
LISTEN_ADDRESS="${ANYTYPE_LISTEN_ADDRESS:-0.0.0.0:31012}"

# Trap signals and forward to background server during init
cleanup() {
    if [ -n "$SERVER_PID" ]; then
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
    fi
    exit 0
}

trap cleanup TERM INT HUP

# If credentials don't exist, do the init dance
if [ ! -f "$CREDS_FILE" ]; then
    echo "No credentials found. Running initialization..."

    # Start server in background for auth
    anytype serve --quiet --listen-address "$LISTEN_ADDRESS" &
    SERVER_PID=$!

    # Wait for gRPC server to be ready (auth create uses gRPC)
    echo "Waiting for gRPC server to start..."
    for i in $(seq 1 30); do
        if nc -z localhost 31010 2>/dev/null; then
            echo "Server is ready"
            sleep 2
            break
        fi
        sleep 1
    done

    # Create credentials
    echo "Creating account: $BOT_NAME"
    anytype auth create "$BOT_NAME"
    echo "Credentials created successfully"

    # Stop the background server
    kill $SERVER_PID
    wait $SERVER_PID 2>/dev/null || true
    unset SERVER_PID

    echo "Restarting server with credentials..."
fi

# Start server in foreground - exec replaces shell, signals go directly to process
exec anytype serve --quiet --listen-address "$LISTEN_ADDRESS"
