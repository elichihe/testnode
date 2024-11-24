#!/bin/bash

# Advanced Bash Script to run the commands in a screen session

# Set the screen session name
SESSION_NAME="glacier-node"

# Check if the screen session already exists
if screen -list | grep -q "\.${SESSION_NAME}\b"; then
    echo "Screen session '${SESSION_NAME}' already exists. Attaching to it..."
    screen -r "$SESSION_NAME"
else
    echo "Creating a new screen session named '${SESSION_NAME}'..."
    screen -dmS "$SESSION_NAME" bash -c "
        # Inside the screen session
        echo 'Setting executable permissions for verifier_linux_amd64...'
        chmod +x verifier_linux_amd64
        
        echo 'Running ./verifier_linux_amd64...'
        ./verifier_linux_amd64
    "
    echo "Screen session '${SESSION_NAME}' started. Use 'screen -r ${SESSION_NAME}' to reattach."
fi
