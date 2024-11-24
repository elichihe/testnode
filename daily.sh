#!/bin/bash

# Function to check if a Docker container is running
is_container_running() {
    docker ps --filter "name=$1" --format "{{.Names}}" | grep -q "$1"
}

# Function to start a screen session and run commands in it
start_screen_session() {
    local session_name=$1
    local commands=$2

    if screen -list | grep -q "$session_name"; then
        echo "Screen session '$session_name' already exists."
    else
        echo "Creating and starting screen session '$session_name'..."
        screen -dmS "$session_name" bash -c "$commands"
    fi
}

# Cleanup dead screen sessions
echo "Cleaning up dead screen sessions..."
screen -wipe

echo "Starting daily checks..."

# Step 1: Check and run Docker containers
containers=("determined_shirley" "heuristic_nash" "icn_container")

for container in "${containers[@]}"; do
    if is_container_running "$container"; then
        echo "Docker container '$container' is already running."
    else
        echo "Starting Docker container '$container'..."
        docker start "$container" || echo "Failed to start container '$container'."
    fi
done

# Step 2: Check if Vanamine containers are running
if is_container_running "miner-ollama-1" && is_container_running "miner-sixgpt3-1"; then
    echo "Vanamine is running."
else
    echo "Vanamine is not running. Starting Vanamine..."
    start_screen_session "vanamine" "cd Vananode/miner && docker compose up"
fi

# Step 3: Start Blockmesh in a screen session
start_screen_session "blockmesh" "cd Blockmesh && chmod +x blockmesh.sh && ./blockmesh.sh"

# Step 4: Start HemiPop script
echo "Starting HemiPop script..."
cd HemiPop/heminetwork_v0.5.0_linux_amd64 || {
    echo "Failed to find HemiPop directory."
    exit 1
}
chmod +x popstart.sh && ./popstart.sh

# Step 5: Run Glacier script
echo "Running Glacier script..."
cd ../../Glacier || {
    echo "Failed to find Glacier directory."
    exit 1
}
chmod +x glacier.sh && ./glacier.sh

# Step 6: Display running Docker containers
echo "Final list of running Docker containers:"
docker ps

echo "Daily checks and startup script completed."
