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

# Install runtime dependencies
RUN apk add --no-cache ca-certificates && \
    adduser -D -h /home/anytype anytype

# Copy the installed binary from builder
COPY --from=builder /root/.local/bin/anytype /usr/local/bin/anytype

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

# Set the entrypoint to run anytype serve
# Use --listen-address 0.0.0.0:31012 to bind to all interfaces for Docker
ENTRYPOINT ["anytype"]
CMD ["serve", "--quiet", "--listen-address", "0.0.0.0:31012"]
