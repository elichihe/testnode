#!/bin/bash

# Set directories dynamically
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFIER_DIR="$BASE_DIR/verifier"
ENV_FILE="$BASE_DIR/nil.env"
CREDENTIALS_FILE="$VERIFIER_DIR/credentials.json"

# Function to read JSON keys from nil.env
read_env_var() {
    local key=$1
    jq -r ".$key" "$ENV_FILE" 2>/dev/null
}

# Remove existing credentials.json
remove_old_credentials() {
    if [ -f "$CREDENTIALS_FILE" ]; then
        echo "Removing existing $CREDENTIALS_FILE..."
        rm -f "$CREDENTIALS_FILE"
    else
        echo "No existing $CREDENTIALS_FILE found."
    fi
}

# Create new credentials.json
create_new_credentials() {
    echo "Creating new $CREDENTIALS_FILE..."

    # Extract values from nil.env
    PRIV_KEY=$(read_env_var "priv_key")
    PUB_KEY=$(read_env_var "pub_key")
    ADDRESS=$(read_env_var "address")

    # Check if keys are valid
    if [[ -z "$PRIV_KEY" || -z "$PUB_KEY" || -z "$ADDRESS" ]]; then
        echo "Error: Missing keys in $ENV_FILE. Please ensure priv_key, pub_key, and address are present."
        exit 1
    fi

    # Create the credentials.json
    cat <<EOF > "$CREDENTIALS_FILE"
{
  "priv_key": "$PRIV_KEY",
  "pub_key": "$PUB_KEY",
  "address": "$ADDRESS"
}
EOF

    echo "$CREDENTIALS_FILE created successfully."
}

# Main script
main() {
    echo "Starting the nilchange.sh script..."

    # Check if jq is installed
    if ! command -v jq &>/dev/null; then
        echo "Error: jq is not installed. Please install jq to use this script."
        exit 1
    fi

    # Check if nil.env exists
    if [ ! -f "$ENV_FILE" ]; then
        echo "Error: $ENV_FILE does not exist."
        exit 1
    fi

    remove_old_credentials
    create_new_credentials
    echo "Script execution completed."
}

# Run the main function
main
