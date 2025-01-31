#!/bin/bash

# Get the directory where the script is being run
BASE_DIR="$(pwd)"
CONFIG_DIR="$BASE_DIR/config"
CONTAINER_IMAGE="privasea/acceleration-node-beta:latest"
KEYSTORE_FILE="$CONFIG_DIR/wallet_keystore"
ENV_FILE="$BASE_DIR/pri.env"

# Ensure config directory exists
echo "Creating configuration directory at $CONFIG_DIR..."
sudo mkdir -p "$CONFIG_DIR"



# Run Docker container to create keystore
echo "Generating new keystore..."
docker run --rm -it -v "$CONFIG_DIR:/app/config" "$CONTAINER_IMAGE" ./node-calc new_keystore

# Find generated keystore file
GENERATED_KEYSTORE=$(ls "$CONFIG_DIR"/UTC--* 2>/dev/null)

if [ -z "$GENERATED_KEYSTORE" ]; then
    echo "Keystore generation failed! Exiting."
    exit 1
fi

# Rename the keystore file
echo "Renaming keystore..."
sudo mv "$GENERATED_KEYSTORE" "$KEYSTORE_FILE"

# Remove the generated keystore
echo "Removing existing keystore..."
sudo rm -rf "$KEYSTORE_FILE"

# Restore keystore from pri.env
if [ -f "$ENV_FILE" ]; then
    echo "Restoring keystore from pri.env..."
    sudo cp "$ENV_FILE" "$KEYSTORE_FILE"

    # Validate that the keystore is in JSON format
    if ! jq empty "$KEYSTORE_FILE" 2>/dev/null; then
        echo "Error: pri.env is not a valid JSON file. Exiting."
        exit 1
    fi
else
    echo "pri.env file not found in $BASE_DIR! Exiting."
    exit 1
fi

# Run the node container
echo "Starting privanetix-node..."
KEYSTORE_PASSWORD="Naksari7"
docker run -d --name privanetix-node -v "$CONFIG_DIR:/app/config" -e KEYSTORE_PASSWORD="$KEYSTORE_PASSWORD" "$CONTAINER_IMAGE"

echo "Process completed successfully!"
