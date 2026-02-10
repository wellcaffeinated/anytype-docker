# Build stage: Install anytype-cli using the official install script
FROM alpine:3.23 AS builder

# Install dependencies required by the install script
RUN apk add --no-cache bash curl tar ca-certificates

# Copy the install script
COPY install.sh /tmp/install.sh

# Run the install script (installs to ~/.local/bin)
RUN chmod +x /tmp/install.sh && \
    /tmp/install.sh

# Final stage: Minimal runtime image
FROM alpine:3.23

# Install runtime dependencies including tini
RUN apk add --no-cache ca-certificates netcat-openbsd tini && \
    adduser -D -h /home/anytype anytype

# Copy the installed binary from builder
COPY --from=builder /root/.local/bin/anytype /usr/local/bin/anytype

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create directory for anytype data
RUN mkdir -p /anytype
RUN chown anytype /anytype

# Switch to non-root user
USER anytype
WORKDIR /home/anytype

# Expose ports for gRPC, gRPC-Web, and HTTP API
# 31010: gRPC server endpoint
# 31011: gRPC-Web server endpoint
# 31012: HTTP API server endpoint (main)
EXPOSE 31010 31011 31012

ENV ANYTYPE_LOG_LEVEL=INFO
ENV DATA_PATH=/anytype
ENV ANYTYPE_LISTEN_ADDRESS=0.0.0.0:31012

# Use tini as PID 1 to handle signals and reaping
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/entrypoint.sh"]
