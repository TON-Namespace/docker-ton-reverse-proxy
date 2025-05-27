FROM ubuntu:22.04

# Install required packages
RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /app

# Download and install tonutils reverse proxy
RUN wget https://github.com/tonutils/reverse-proxy/releases/latest/download/tonutils-reverse-proxy-linux-amd64 -O /usr/local/bin/tonutils-reverse-proxy-linux-amd64
RUN chmod +x /usr/local/bin/tonutils-reverse-proxy-linux-amd64

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set environment variables with defaults
ENV DOMAIN=""
ENV PROXY_PASS=""
ENV EXTERNAL_IP=""
ENV LISTEN_IP="0.0.0.0"
ENV PORT="8765"
ENV NETWORK_CONFIG_URL="https://ton.org/global.config.json"
ENV FIRST_INIT="false"
ENV TX_URL="false"

# Expose the port
# Use entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
