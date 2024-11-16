#!/bin/bash

# Define paths
SCRIPT_DIR=$(dirname "$(realpath "$0")")   # Get the script's directory
ENV_FILE="$SCRIPT_DIR/hemi.env"             # Path to hemi.env
POPMD="$SCRIPT_DIR/popmd"                   # Absolute path to popmd
SCREEN_SESSION="popmine"                   # Screen session name

# Function to read values from hemi.env (JSON format)
read_env_var() {
    local key=$1
    jq -r ".$key" "$ENV_FILE" 2>/dev/null
}

# Main script
main() {
    echo "Starting popstart.sh..."

    # Check if jq is installed
    if ! command -v jq &>/dev/null; then
        echo "Error: jq is not installed. Please install jq to use this script."
        exit 1
    fi

    # Check if hemi.env exists
    if [ ! -f "$ENV_FILE" ]; then
        echo "Error: $ENV_FILE does not exist in the current directory."
        exit 1
    fi

    # Extract private_key from hemi.env
    PRIVATE_KEY=$(read_env_var "private_key")

    # Validate private_key
    if [[ -z "$PRIVATE_KEY" ]]; then
        echo "Error: private_key is missing in $ENV_FILE."
        exit 1
    fi

    # Set environment variables
    export POPM_BTC_PRIVKEY="$PRIVATE_KEY"
    export POPM_STATIC_FEE=350
    export POPM_BFG_URL="wss://testnet.rpc.hemi.network/v1/ws/public"

    echo "Environment variables set:"
    echo "POPM_BTC_PRIVKEY=$POPM_BTC_PRIVKEY"
    echo "POPM_STATIC_FEE=$POPM_STATIC_FEE"
    echo "POPM_BFG_URL=$POPM_BFG_URL"

    # Check if popmd exists
    if [ ! -f "$POPMD" ]; then
        echo "Error: $POPMD does not exist. Please ensure popmd is present in the script directory."
        exit 1
    fi

    # Start a new screen session and run popmd
    echo "Running $POPMD in screen session '$SCREEN_SESSION'..."
    screen -dmS "$SCREEN_SESSION" bash -c "$POPMD; exec bash"

    # Detach from the screen session
    echo "Detached from screen session '$SCREEN_SESSION'."
    screen -S "$SCREEN_SESSION" -X detach

    echo "popstart.sh execution completed."
}

# Run the main function
main
