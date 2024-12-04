#!/bin/bash

# Get the directory where setup.sh is located
SCRIPT_DIR=$(dirname "$(realpath "$0")")
LOG_FILE="$SCRIPT_DIR/setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Utility functions
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $*"
}

run_command() {
    log "Running: $*"
    eval "$*"
    if [ $? -ne 0 ]; then
        log "Error: Command failed - $*"
        exit 1
    fi
}

run_in_screen() {
    local screen_name=$1
    shift
    log "Creating and running commands in screen: $screen_name"
    screen -dmS "$screen_name" bash -c "$*; exec bash"
}

ask_user() {
    local question=$1
    local default=$2
    read -p "$question (y/n, default: $default): " choice
    choice=${choice:-$default}
    case "$choice" in
        y|Y) return 0 ;;
        n|N) return 1 ;;
        *) log "Invalid input, assuming default: $default"; return $([[ $default == "y" ]] && echo 0 || echo 1) ;;
    esac
}

prompt_for_input() {
    local prompt_message=$1
    local input_var
    read -p "$prompt_message: " input_var
    echo "$input_var"
}

add_delay() {
    local seconds=$1
    log "Waiting for $seconds seconds to prevent CPU overloading..."
    sleep "$seconds"
}

check_screen() {
    local screen_name=$1
    if screen -list | grep -q "$screen_name"; then
        if ask_user "Screen '$screen_name' already exists. Do you want to rerun this service?" "n"; then
            log "Stopping existing screen: $screen_name"
            screen -S "$screen_name" -X quit
            return 0
        else
            log "Skipping: $screen_name"
            return 1
        fi
    fi
    return 0
}

log "Starting setup process..."

# System update and dependency installation
log "Updating and upgrading system packages..."
run_command "sudo apt update && sudo apt upgrade -y"

log "Installing screen utility..."
run_command "sudo apt install screen -y"

log "Installing jq JSON parser..."
run_command "sudo apt-get install jq -y"

# Ask user if they want to run all services or selectively
if ask_user "Do you want to run all services?" "y"; then
    run_all_services=true
else
    run_all_services=false
fi

should_run_service() {
    local service_name=$1
    if [ "$run_all_services" = true ]; then
        return 0
    else
        ask_user "Do you want to run the $service_name service?" "y"
        return $?
    fi
}

# Service definitions
run_vanamine() {
    run_in_screen "vanamine" "
        cd $SCRIPT_DIR/Vananode/miner &&
        docker-compose up -d
    "
    log "Detached screen: vanamine"
    add_delay 10
}

run_blockmesh() {
    run_in_screen "blockmesh" "
        cd $SCRIPT_DIR/Blockmesh &&
        chmod +x blockmesh.sh &&
        ./blockmesh.sh
    "
    log "Detached screen: blockmesh"
    add_delay 10
}

run_hemimine() {
    run_in_screen "hemimine" "
        cd $SCRIPT_DIR/HemiPop/heminetwork_v0.5.0_linux_amd64 &&
        ./keygen -secp256k1 -json -net='testnet' > ~/popm-address.json
    "
    if ask_user "Do you want to use custom keys for hemimine?" "n"; then
        run_command "chmod +x $SCRIPT_DIR/HemiPop/heminetwork_v0.5.0_linux_amd64/hemichange.sh"
        run_command "$SCRIPT_DIR/HemiPop/heminetwork_v0.5.0_linux_amd64/hemichange.sh"
    else
        log "Using default keys for hemimine. Ensure you save your keys securely!"
    fi
    run_command "chmod +x $SCRIPT_DIR/HemiPop/heminetwork_v0.5.0_linux_amd64/popstart.sh"
    run_command "$SCRIPT_DIR/HemiPop/heminetwork_v0.5.0_linux_amd64/popstart.sh"
    log "Detached screen: hemimine"
    add_delay 10
}

run_nillion() {
    log "Pulling Nillion verifier image..."
    run_command "docker pull nillion/verifier:v1.0.1"

    log "Ensuring verifier directory exists..."
    run_command "mkdir -p $SCRIPT_DIR/Nillion/nillion/verifier"

    log "Initializing Nillion verifier..."
    run_command "docker run -v $SCRIPT_DIR/Nillion/nillion/verifier:/var/tmp nillion/verifier:v1.0.1 initialise"

    log "Verifier initialization complete. Proceeding to custom key setup..."
    if ask_user "Do you want to use custom keys for nillion?" "n"; then
        log "Setting up custom keys for Nillion..."
        run_command "chmod +x $SCRIPT_DIR/Nillion/nilchange.sh"
        run_command "$SCRIPT_DIR/Nillion/nilchange.sh"
    else
        log "Using default keys for Nillion. Ensure you save your keys securely!"
    fi

    log "Starting Nillion verifier in detached mode..."
    run_command "docker run -d -v $SCRIPT_DIR/Nillion/nillion/verifier:/var/tmp nillion/verifier:v1.0.1 verify --rpc-endpoint 'https://testnet-nillion-rpc.lavenderfive.com'"
    log "Detached screen: nillion"
    add_delay 10
}


run_titan() {
    run_in_screen "titan" "
        cd $SCRIPT_DIR/Titan &&
        chmod +x titan.sh &&
        ./titan.sh
    "

    log "Titan is running in a screen session. Waiting briefly to attach and provide input..."
    sleep 5  # Wait to ensure the script initializes

    log "Prompting the user for input..."
    titan_input=$(prompt_for_input "Enter the required input for titan.sh")

    log "Attaching to the 'titan' screen session to provide input..."
    screen -S titan -X stuff "${titan_input}\n"

    log "Input sent to the 'titan' screen session. Detaching..."
    add_delay 10

    # Bind Titan container with hash key
    docker_command="docker run --rm -it -v ~/.titanedge:/root/.titanedge nezha123/titan-edge bind --hash=hashkey https://api-test1.container1.titannet.io/api/v2/device/binding"
    hashkey=$(prompt_for_input "Enter the hash key for Titan binding")
    log "Running Titan bind command with hash key..."
    run_command "${docker_command//hashkey/$hashkey}"
}

# Service Execution
if should_run_service "vanamine"; then check_screen "vanamine" && run_vanamine; fi
if should_run_service "blockmesh"; then check_screen "blockmesh" && run_blockmesh; fi
if should_run_service "hemimine"; then check_screen "hemimine" && run_hemimine; fi
if should_run_service "nillion"; then check_screen "nillion" && run_nillion; fi
if should_run_service "titan"; then check_screen "titan" && run_titan; fi

log "Setup process completed successfully!"
log "Check the log file: $LOG_FILE for details."
