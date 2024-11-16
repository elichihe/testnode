#!/bin/bash

# Define paths
SCRIPT_DIR=$(dirname "$(realpath "$0")")  # Get the script's directory
ENV_FILE="$SCRIPT_DIR/hemi.env"            # Path to hemi.env in the same directory as this script
POPM_FILE="$HOME/popm-address.json"       # Path to popm-address.json

# Function to read values from hemi.env (JSON format)
read_env_var() {
    local key=$1
    jq -r ".$key" "$ENV_FILE" 2>/dev/null
}

# Remove the existing popm-address.json
remove_old_popm_file() {
    if [ -f "$POPM_FILE" ]; then
        echo "Removing existing $POPM_FILE..."
        rm -f "$POPM_FILE"
    else
        echo "No existing $POPM_FILE found."
    fi
}

# Create a new popm-address.json
create_new_popm_file() {
    echo "Creating new $POPM_FILE..."

    # Extract values from hemi.env
    ETHEREUM_ADDRESS=$(read_env_var "ethereum_address")
    NETWORK=$(read_env_var "network")
    PRIVATE_KEY=$(read_env_var "private_key")
    PUBLIC_KEY=$(read_env_var "public_key")
    PUBKEY_HASH=$(read_env_var "pubkey_hash")

    # Validate keys
    if [[ -z "$ETHEREUM_ADDRESS" || -z "$NETWORK" || -z "$PRIVATE_KEY" || -z "$PUBLIC_KEY" || -z "$PUBKEY_HASH" ]]; then
        echo "Error: Missing keys in $ENV_FILE. Please ensure all required fields are present."
        exit 1
    fi

    # Create the new popm-address.json
    cat <<EOF > "$POPM_FILE"
{
  "ethereum_address": "$ETHEREUM_ADDRESS",
  "network": "$NETWORK",
  "private_key": "$PRIVATE_KEY",
  "public_key": "$PUBLIC_KEY",
  "pubkey_hash": "$PUBKEY_HASH"
}
EOF

    echo "New $POPM_FILE created successfully."
}

# Main script
main() {
    echo "Starting hemichange.sh..."

    # Check if jq is installed
    if ! command -v jq &>/dev/null; then
        echo "Error: jq is not installed. Please install jq to use this script."
        exit 1
    fi

    # Check if hemi.env exists in the correct directory
    if [ ! -f "$ENV_FILE" ]; then
        echo "Error: $ENV_FILE does not exist in the current directory ($SCRIPT_DIR)."
        exit 1
    fi

    remove_old_popm_file
    create_new_popm_file
    echo "Script execution completed."
}

# Run the main function
main
