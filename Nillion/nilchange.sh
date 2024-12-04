#!/bin/bash

# Dynamically set base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$BASE_DIR")"
NILLION_DIR="$WORKSPACE_DIR/Nillion"
VERIFIER_DIR="$NILLION_DIR/nillion/verifier"
ENV_FILE="$NILLION_DIR/nil.env"
CREDENTIALS_FILE="$VERIFIER_DIR/credentials.json"

# Function to read JSON keys from nil.env
read_env_var() {
    local key=$1
    jq -r ".$key" "$ENV_FILE" 2>/dev/null
}

# Remove existing credentials.json
remove_existing_credentials() {
    if [ -f "$CREDENTIALS_FILE" ]; then
        echo "Existing $CREDENTIALS_FILE found. Deleting it..."
        rm -f "$CREDENTIALS_FILE"
        if [ $? -eq 0 ]; then
            echo "Successfully deleted $CREDENTIALS_FILE."
        else
            echo "Error: Failed to delete $CREDENTIALS_FILE."
            exit 1
        fi
    else
        echo "No existing $CREDENTIALS_FILE found. Proceeding to create a new one."
    fi
}

# Create a new credentials.json
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

    # Ensure verifier directory exists
    mkdir -p "$VERIFIER_DIR"

    # Create the credentials.json
    cat <<EOF > "$CREDENTIALS_FILE"
{
  "priv_key": "$PRIV_KEY",
  "pub_key": "$PUB_KEY",
  "address": "$ADDRESS"
}
EOF

    if [ $? -eq 0 ]; then
        echo "$CREDENTIALS_FILE created successfully."
    else
        echo "Error: Failed to create $CREDENTIALS_FILE."
        exit 1
    fi
}

# Main script
main() {
    echo "Starting the advanced nilchange.sh script..."

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

    # Remove existing credentials.json if it exists
    remove_existing_credentials

    # Create a new credentials.json
    create_new_credentials

    echo "Script execution completed successfully."
}

# Run the main function
main
