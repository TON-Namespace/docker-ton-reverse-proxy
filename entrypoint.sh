#!/bin/bash

# Function to update config.json with environment variables
update_config() {
    local config_file="$1"
    
    echo "Updating existing config.json with environment variables..."
    
    # Create a temporary config with updates
    jq --arg proxy_pass "$PROXY_PASS" \
       --arg external_ip "$EXTERNAL_IP" \
       --arg listen_ip "$LISTEN_IP" \
       --arg network_config_url "$NETWORK_CONFIG_URL" \
       --argjson port "$PORT" \
       '.proxy_pass = $proxy_pass |
        .external_ip = $external_ip |
        .listen_ip = $listen_ip |
        .network_config_url = $network_config_url |
        .port = $port' "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"
    
    echo "Config updated successfully!"
}

# Check if this is first initialization
if [ "$FIRST_INIT" = "true" ]; then
    echo "=== FIRST INITIALIZATION MODE ==="
    
    if [ -z "$DOMAIN" ]; then
        echo "Error: DOMAIN environment variable is required for first initialization"
        echo "Example: DOMAIN=namespace.ton"
        exit 1
    fi
    
    echo "Initializing tonutils reverse proxy for domain: $DOMAIN"
    echo "This will create a new config.json and show a QR code for domain setup."
    echo ""
    
    # Check if config already exists
    if [ -f "/app/config.json" ]; then
        echo "Warning: config.json already exists. Backing up to config.json.backup"
        cp /app/config.json /app/config.json.backup
    fi
    
    # Build command arguments
    INIT_ARGS="--domain $DOMAIN"
    
    if [ "$TX_URL" = "true" ]; then
        INIT_ARGS="$INIT_ARGS --tx-url"
        echo "Transaction URL mode enabled (no QR code will be shown)"
    else
        echo "QR code mode enabled"
    fi
    
    echo "Running initialization command..."
    echo "Command: ./tonutils-reverse-proxy-linux-amd64 $INIT_ARGS"
    echo ""
    
    # Run initialization
    ./tonutils-reverse-proxy-linux-amd64 $INIT_ARGS
    
    # Check if config was created
    if [ -f "/app/config.json" ]; then
        echo ""
        echo "✅ Initialization completed successfully!"
        echo "📁 Config file created at: /app/config.json"
        echo ""
        echo "Next steps:"
        echo "1. Scan the QR code above with the domain owner's wallet (if QR mode)"
        echo "2. Or use the transaction URL to set the ADNL address (if TX_URL mode)"
        echo "3. After the transaction is confirmed, restart the container with FIRST_INIT=false"
        echo "4. Set the required environment variables (PROXY_PASS, EXTERNAL_IP, etc.)"
        echo ""
        echo "Generated config.json:"
        cat /app/config.json | jq .
    else
        echo "❌ Error: config.json was not created during initialization"
        exit 1
    fi
    
    exit 0
fi

# Normal operation mode
echo "=== NORMAL OPERATION MODE ==="

# Check if config.json exists
if [ ! -f "/app/config.json" ]; then
    echo "❌ Error: config.json not found!"
    echo ""
    echo "You need to run first initialization:"
    echo "1. Set FIRST_INIT=true"
    echo "2. Set DOMAIN=your-domain.ton"
    echo "3. Run the container to generate config.json"
    echo "4. Complete the domain setup transaction"
    echo "5. Then run with FIRST_INIT=false and proper environment variables"
    exit 1
fi

echo "Found existing config.json"

# Validate required environment variables for normal operation
MISSING_VARS=()

if [ -z "$PROXY_PASS" ]; then
    MISSING_VARS+=("PROXY_PASS")
fi

if [ -z "$EXTERNAL_IP" ]; then
    MISSING_VARS+=("EXTERNAL_IP")
fi

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo "❌ Error: Missing required environment variables:"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "Required variables:"
    echo "  PROXY_PASS: Backend URL to proxy to (e.g., https://namespace.my/)"
    echo "  EXTERNAL_IP: External IP address of your server"
    echo ""
    echo "Optional variables:"
    echo "  LISTEN_IP: IP to bind to (default: 0.0.0.0)"
    echo "  PORT: Port to listen on (default: 8765)"
    echo "  NETWORK_CONFIG_URL: TON network config URL"
    exit 1
fi

# Update config.json with environment variables
update_config "/app/config.json"

echo ""
echo "Updated config.json:"
cat /app/config.json | jq .

echo ""
echo "🚀 Starting tonutils reverse proxy..."
echo "📡 Listening on: $LISTEN_IP:$PORT"
echo "🔄 Proxying to: $PROXY_PASS"
echo "🌐 External IP: $EXTERNAL_IP"
echo ""

# Start the reverse proxy
exec ./tonutils-reverse-proxy-linux-amd64
