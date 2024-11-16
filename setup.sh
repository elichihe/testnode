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

# Screen: vanamine
if should_run_service "vanamine"; then
    if check_screen "vanamine"; then
        run_in_screen "vanamine" "
            cd $SCRIPT_DIR/Vananode/miner &&
            docker-compose up -d
        "
        log "Detached screen: vanamine"
        add_delay 10
    fi
fi

# Screen: blockmesh
if should_run_service "blockmesh"; then
    if check_screen "blockmesh"; then
        run_in_screen "blockmesh" "
            cd $SCRIPT_DIR/Blockmesh &&
            chmod +x blockmesh.sh &&
            ./blockmesh.sh
        "
        log "Detached screen: blockmesh"
        add_delay 10
    fi
fi

# Screen: hemimine
if should_run_service "hemimine"; then
    if check_screen "hemimine"; then
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
    fi
fi

# Screen: icn
if should_run_service "icn"; then
    if check_screen "icn"; then
        run_in_screen "icn" "
            cd $SCRIPT_DIR/ICN/icn-docker &&
            docker build -t icn_installer . &&
            docker run --name icn_container icn_installer
        "
        log "Detached screen: icn"
        add_delay 10
    fi
fi

# Screen: nillion
if should_run_service "nillion"; then
    if check_screen "nillion"; then
        run_in_screen "nillion" "
            cd $SCRIPT_DIR/Nillion &&
            docker pull nillion/verifier:v1.0.1 &&
            docker run -v $SCRIPT_DIR/Nillion/nillion/verifier:/var/tmp nillion/verifier:v1.0.1 initialise
        "
        if ask_user "Do you want to use custom keys for nillion?" "n"; then
            run_command "chmod +x $SCRIPT_DIR/Nillion/nilchange.sh"
            run_command "$SCRIPT_DIR/Nillion/nilchange.sh"
        else
            log "Using default keys for nillion. Ensure you save your keys securely!"
        fi
        run_command "docker run -d -v $SCRIPT_DIR/Nillion/nillion/verifier:/var/tmp nillion/verifier:v1.0.1 verify --rpc-endpoint 'https://testnet-nillion-rpc.lavenderfive.com'"
        log "Detached screen: nillion"
        add_delay 10
    fi
fi

# Screen: titan
if should_run_service "titan"; then
    if check_screen "titan"; then
        run_in_screen "titan" "
            cd $SCRIPT_DIR/Titan &&
            chmod +x titan.sh &&
            ./titan.sh &&
            chmod +x titan.sh &&
            ./titan.sh
        "
        log "Detached screen: titan"
        add_delay 10
    fi
fi

# Screen: volara
if should_run_service "volara"; then
    if check_screen "volara"; then
        run_in_screen "volara" "
            cd $SCRIPT_DIR/Volara &&
            chmod +x volara.sh &&
            ./volara.sh
        "
        log "Detached screen: volara"
        add_delay 10
    fi
fi

log "Setup process completed successfully!"
log "Check the log file: $LOG_FILE for details."