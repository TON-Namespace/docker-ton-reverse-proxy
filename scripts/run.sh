#!/bin/bash

# Run script for tonutils reverse proxy

set -e

PROXY_PASS=${1:-""}
EXTERNAL_IP=${2:-""}
PORT=${3:-"8765"}

if [ -z "$PROXY_PASS" ] || [ -z "$EXTERNAL_IP" ]; then
    echo "Usage: $0 <proxy_pass> <external_ip> [port]"
    echo "Example: $0 https://namespace.my/ 104.***.***.104"
    echo "Example: $0 https://namespace.my/ 104.***.***.104 8080"
    exit 1
fi

echo "Starting tonutils reverse proxy..."
echo "Proxy Pass: $PROXY_PASS"
echo "External IP: $EXTERNAL_IP"
echo "Port: $PORT"

# Check if config exists
if [ ! -f "./tonutils-config/config.json" ]; then
    echo "Error: config.json not found!"
    echo "Please run initialization first: ./scripts/init.sh <domain>"
    exit 1
fi

# Run the proxy
docker run -d \
  --name tonutils-proxy \
  -p "$PORT:$PORT" \
  -v $(pwd)/tonutils-config:/app \
  -e PROXY_PASS="$PROXY_PASS" \
  -e EXTERNAL_IP="$EXTERNAL_IP" \
  -e PORT="$PORT" \
  reverse-proxy:latest

echo "Proxy started successfully!"
echo "Container name: tonutils-proxy"
echo "Logs: docker logs -f tonutils-proxy"
