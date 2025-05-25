# TON Utils Reverse Proxy Docker

A Docker image for running [tonutils reverse proxy](https://github.com/tonutils/reverse-proxy) to serve websites through TON DNS domains.
c
## Quick Start

### Step 1: First Initialization

First, you need to initialize the proxy and set up your TON domain:

\`\`\`bash
# Create a directory for config persistence
mkdir -p ./tonutils-config

# Run first initialization
docker run -it --rm \
  -v $(pwd)/tonutils-config:/app \
  -e FIRST_INIT=true \
  -e DOMAIN="namespace.ton" \
  tonnamespace/reverse-proxy:latest
\`\`\`

This will:
1. Generate a new private key and config.json
2. Show a QR code for setting up the ADNL address
3. Save the config to your local directory

### Step 2: Complete Domain Setup

Scan the QR code with the domain owner's wallet to set the ADNL address, or use the transaction URL if you used `TX_URL=true`.

### Step 3: Run the Proxy

After the transaction is confirmed, run the proxy normally:

\`\`\`bash
docker run -d \
  --name tonutils-proxy \
  -p 8765:8765 \
  -v $(pwd)/tonutils-config:/app \
  -e PROXY_PASS="https://namespace.my/" \
  -e EXTERNAL_IP="your_server_ip" \
  tonnamespace/reverse-proxy:latest
\`\`\`

## Environment Variables

### Required for First Initialization

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `FIRST_INIT` | ✅ | `false` | Set to `true` for first-time setup |
| `DOMAIN` | ✅ (if FIRST_INIT=true) | - | TON domain to serve (e.g., `namespace.ton`) |

### Required for Normal Operation

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PROXY_PASS` | ✅ | - | Backend URL to proxy to (e.g., `https://namespace.my/`) |
| `EXTERNAL_IP` | ✅ | - | External IP address of your server |

### Optional Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `LISTEN_IP` | ❌ | `0.0.0.0` | IP address to bind to |
| `PORT` | ❌ | `8765` | Port to listen on |
| `NETWORK_CONFIG_URL` | ❌ | `https://ton.org/global.config.json` | TON network config URL |
| `TX_URL` | ❌ | `false` | Set to `true` to get transaction URL instead of QR code |

## Complete Setup Example

### 1. Initialize with QR Code

\`\`\`bash
mkdir -p ./tonutils-config

docker run -it --rm \
  -v $(pwd)/tonutils-config:/app \
  -e FIRST_INIT=true \
  -e DOMAIN="mydomain.ton" \
  tonnamespace/reverse-proxy:latest
\`\`\`

### 2. Initialize with Transaction URL

\`\`\`bash
mkdir -p ./tonutils-config

docker run -it --rm \
  -v $(pwd)/tonutils-config:/app \
  -e FIRST_INIT=true \
  -e DOMAIN="mydomain.ton" \
  -e TX_URL=true \
  tonnamespace/reverse-proxy:latest
\`\`\`

### 3. Run the Proxy

\`\`\`bash
docker run -d \
  --name my-ton-proxy \
  -p 8765:8765 \
  -v $(pwd)/tonutils-config:/app \
  -e PROXY_PASS="https://mywebsite.com/" \
  -e EXTERNAL_IP="1.2.3.4" \
  -e PORT="8765" \
  tonnamespace/reverse-proxy:latest
\`\`\`

## Docker Compose Example

\`\`\`yaml
version: '3.8'

services:
  # First run this for initialization
  tonutils-init:
    image: tonnamespace/reverse-proxy:latest
    container_name: tonutils-init
    volumes:
      - ./tonutils-config:/app
    environment:
      - FIRST_INIT=true
      - DOMAIN=namespace.ton
      - TX_URL=false  # Set to true for transaction URL instead of QR
    profiles:
      - init

  # Then run this for normal operation
  tonutils-proxy:
    image: tonnamespace/reverse-proxy:latest
    container_name: tonutils-proxy
    ports:
      - "8765:8765"
    volumes:
      - ./tonutils-config:/app
    environment:
      - PROXY_PASS=https://namespace.my/
      - EXTERNAL_IP=YOUR_HOST_EXTERNAL_IP
      - LISTEN_IP=0.0.0.0
      - PORT=8765
    restart: unless-stopped
    profiles:
      - proxy
\`\`\`

Run initialization:
\`\`\`bash
docker-compose --profile init up tonutils-init
\`\`\`

Run proxy:
\`\`\`bash
docker-compose --profile proxy up -d tonutils-proxy
\`\`\`

## Configuration

The container automatically manages the `config.json` file:

1. **First initialization**: Creates a new config with generated private key
2. **Normal operation**: Updates existing config with environment variables

Example generated config.json:
\`\`\`json
{
  "proxy_pass": "https://namespace.my/",
  "private_key": "e7Y4DtgPtJP1UqlI5jGWhrLOotTWa3EjQwNSfh3akCw=",
  "external_ip": "YOUR_HOST_EXTERNAL_IP",
  "listen_ip": "0.0.0.0",
  "network_config_url": "https://ton.org/global.config.json",
  "custom_tunnel_network_config_url": "",
  "port": 8765,
  "tunnel_config": {
    "TunnelServerKey": "qT8TWTeZWdjMd/Qv7xRbfmYnO4xnJgZ4/UEWEU+tXgs=",
    "TunnelThreads": 1,
    "TunnelSectionsNum": 1,
    "NodesPoolConfigPath": "",
    "PaymentsEnabled": false,
    "Payments": {
      // ... payment configuration
    }
  },
  "version": 1
}
\`\`\`

## Workflow

1. **Initialize**: Run with `FIRST_INIT=true` to create config and get setup transaction
2. **Setup Domain**: Complete the transaction to link your domain to the ADNL address
3. **Run Proxy**: Start the proxy with your backend configuration
4. **Access**: Your website will be available through the TON domain

## Troubleshooting

### "config.json not found" Error
- You need to run first initialization with `FIRST_INIT=true`
- Make sure you're mounting the volume correctly

### QR Code Not Showing
- Ensure you're running in interactive mode (`-it`)
- Try using `TX_URL=true` to get a transaction URL instead

### Domain Not Resolving
- Verify the setup transaction was completed successfully
- Check that your domain is properly configured in TON DNS
- Ensure the external IP is correct and reachable

### Container Exits During Init
- Check that the DOMAIN variable is set correctly
- Ensure the domain format is correct (e.g., `mydomain.ton`)

### Proxy Not Working
- Verify all required environment variables are set
- Check that the backend URL (PROXY_PASS) is accessible
- Ensure the port is properly exposed and not blocked by firewall

## Logs

View initialization logs:
\`\`\`bash
docker logs tonutils-init
\`\`\`

View proxy logs:
\`\`\`bash
docker logs tonutils-proxy
\`\`\`

Follow proxy logs:
\`\`\`bash
docker logs -f tonutils-proxy
\`\`\`

## Security Notes

- The private key is automatically generated and stored in config.json
- Keep your config directory secure and backed up
- Use environment variables for sensitive configuration
- Consider using Docker secrets in production environments

## Building Locally

\`\`\`bash
git clone https://github.com/TON-Namespace/docker-ton-reverse-proxy.git
cd docker-ton-reverse-proxy
docker build -t reverse-proxy .
\`\`\`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the build and functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Links

- [TON Utils Reverse Proxy](https://github.com/tonutils/reverse-proxy)
- [TON Documentation](https://ton.org/docs/)
- [Docker Hub Repository](https://hub.docker.com/r/tonnamespace/reverse-proxy)
