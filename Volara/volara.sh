#!/bin/bash

# Update and upgrade system packages
echo "Updating and upgrading system packages..."
sudo apt update -y && sudo apt upgrade -y

# Remove old Docker-related packages
echo "Removing old Docker-related packages..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove -y $pkg
done

# Install prerequisites for Docker
echo "Installing prerequisites for Docker..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# Set up Docker repository
echo "Setting up Docker repository..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "Adding Docker repository to apt sources..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update and install Docker
echo "Updating apt and installing Docker..."
sudo apt update -y && sudo apt upgrade -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify Docker installation
if ! command -v docker &> /dev/null; then
    echo "Docker installation failed. Exiting..."
    exit 1
fi
echo "Docker version: $(docker --version)"

# Pull the Docker image
echo "Pulling the Docker image 'volara/miner'..."
docker pull volara/miner

# Check for volara.env and load VANA_PRIVATE_KEY
if [[ -f volara.env ]]; then
    echo "Loading VANA_PRIVATE_KEY from volara.env..."
    export $(grep -v '^#' volara.env | xargs)
else
    echo "Error: volara.env file not found. Please create it with VANA_PRIVATE_KEY."
    exit 1
fi

# Verify that VANA_PRIVATE_KEY is loaded
if [[ -z "$VANA_PRIVATE_KEY" ]]; then
    echo "Error: VANA_PRIVATE_KEY is not set in volara.env. Exiting..."
    exit 1
fi

# Run the Docker container with the environment variable
echo "Running the Docker container with VANA_PRIVATE_KEY..."
docker run -it -e VANA_PRIVATE_KEY="${VANA_PRIVATE_KEY}" volara/miner

echo "Script execution completed."