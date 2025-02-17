#!/bin/bash

# Set Variables
POP_BINARY_URL="https://dl.pipecdn.app/v0.2.5/pop"
POP_BINARY_NAME="pop"
CACHE_DIR="download_cache"
POP_ENV_FILE="pop.env"
NODE_ENV_FILE="node.env"
NODE_INFO_FILE="node_info.json"
DOCKER_IMAGE="pop_service"
DOCKER_CONTAINER="pop_container"

# Function to check if command exists
check_command() {
    command -v "$1" >/dev/null 2>&1 || { echo "Error: $1 is not installed. Please install it."; exit 1; }
}

# Check for required commands
check_command wget
check_command docker
check_command jq  # JSON processing tool for node_info.json

# Download the binary if it doesn't exist
if [[ ! -f "$POP_BINARY_NAME" ]]; then
    echo "Downloading $POP_BINARY_NAME..."
    wget "$POP_BINARY_URL" -O "$POP_BINARY_NAME"
else
    echo "$POP_BINARY_NAME already exists, skipping download."
fi

# Make the binary executable
chmod +x "$POP_BINARY_NAME"

# Create required directory
mkdir -p "$CACHE_DIR"

# Ask if the user is a first-time user or experienced
echo "Are you running this for the first time? (yes/no)"
read -r FIRST_TIME_USER

if [[ "$FIRST_TIME_USER" == "yes" ]]; then
    # First-time user: Run normally
    echo "Proceeding with first-time setup..."
    
    # Prompt user for referral code
    echo "Please enter your referral code:"
    read -r REFERRAL_CODE

    # Ensure pop.env exists
    if [[ ! -f "$POP_ENV_FILE" ]]; then
        echo "Error: Configuration file $POP_ENV_FILE not found! Creating a template..."
        cat <<EOF > "$POP_ENV_FILE"
RAM=8
MAX_DISK=500
CACHE_DIR=/data
SOLANA_PUBKEY=your_solana_public_key_here
EOF
        echo "Please edit '$POP_ENV_FILE' to add your Solana Public Key before running again."
        exit 1
    fi

    # Load pop.env variables
    source "$POP_ENV_FILE"

else
    # Experienced user: Generate node_info.json from node.env
    if [[ ! -f "$NODE_ENV_FILE" ]]; then
        echo "Error: Node configuration file $NODE_ENV_FILE not found!"
        exit 1
    fi

    echo "Generating node_info.json from $NODE_ENV_FILE..."

    # Convert node.env (JSON format) to node_info.json
    jq '.' "$NODE_ENV_FILE" > "$NODE_INFO_FILE"

    echo "✅ node_info.json has been created!"
fi

# Create the entrypoint script
cat <<'EOF' > entrypoint.sh
#!/bin/bash

echo "Starting Pop Service..."

# Check if node_info.json exists
if [[ -f "/app/node_info.json" ]]; then
    echo "Experienced user detected, using existing node_info.json..."
else
    echo "First-time user, Pop will generate node_info.json..."
fi

# Start the service
exec /app/pop
EOF

# Make entrypoint script executable
chmod +x entrypoint.sh

# Create the Dockerfile dynamically
cat <<EOF > Dockerfile
FROM ubuntu:latest

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    openssl \
    libssl3 \
    jq \
    && rm -rf /var/lib/apt/lists/*  # Clean up to reduce image size

# Set working directory
WORKDIR /app

# Copy files
COPY pop /app/
COPY pop.env /app/
COPY node_info.json /app/
COPY entrypoint.sh /app/

# Create cache directory
RUN mkdir -p /data

# Make binary and script executable
RUN chmod +x /app/pop /app/entrypoint.sh

# Use the entrypoint script to start the service
ENTRYPOINT ["/app/entrypoint.sh"]
EOF

# Remove any existing container
docker rm -f "$DOCKER_CONTAINER" 2>/dev/null

# Build Docker Image
echo "Building Docker image..."
docker build -t "$DOCKER_IMAGE" .

# Run the Docker container
echo "Running Docker container..."
docker run -d --name "$DOCKER_CONTAINER" \
  -v "$(pwd)/$CACHE_DIR:/data" \
  --restart unless-stopped \
  "$DOCKER_IMAGE"

echo "✅ Service is running in Docker as '$DOCKER_CONTAINER'!"
