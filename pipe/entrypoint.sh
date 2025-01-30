#!/bin/bash

echo "Starting Pop Service..."

# Check if node_info.json exists
if [[ -f "/app/node_info.json" ]]; then
    echo "Experienced user detected, using existing node_info.json..."
else
    echo "First-time user, Pop will generate node_info.json..."
fi

# Start the service
exec /app/pop
