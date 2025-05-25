#!/bin/bash

# Initialization script for tonutils reverse proxy

set -e

DOMAIN=${1:-""}
TX_URL=${2:-"false"}

if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <domain> [tx_url]"
    echo "Example: $0 namespace.ton"
    echo "Example: $0 namespace.ton true"
    exit 1
fi

echo "Initializing tonutils reverse proxy for domain: $DOMAIN"

# Create config directory if it doesn't exist
mkdir -p ./tonutils-config

# Run initialization
docker run -it --rm \
  -v $(pwd)/tonutils-config:/app \
  -e FIRST_INIT=true \
  -e DOMAIN="$DOMAIN" \
  -e TX_URL="$TX_URL" \
  reverse-proxy:latest

echo ""
echo "Initialization completed!"
echo "Next steps:"
echo "1. Complete the transaction shown above"
echo "2. Update docker-compose.yml with your configuration"
echo "3. Run: docker-compose --profile proxy up -d"
