#!/bin/bash

# Define color codes
INFO='\033[0;36m'  # Cyan
WARNING='\033[0;33m'
ERROR='\033[0;31m'
SUCCESS='\033[0;32m'
NC='\033[0m' # No Color

# Function to ensure a non-empty value
get_non_empty_input() {
    local prompt="$1"
    local input=""
    while [ -z "$input" ]; do
        read -p "$prompt" input
        if [ -z "$input" ]; then
            echo -e "${ERROR}Error: This field cannot be empty.${NC}"
        fi
    done
    echo "$input"
}

# Load predefined device-specific identifiers
load_device_identifiers() {
    local env_file="mac.env"
    if [ ! -f "$env_file" ]; then
        echo -e "${ERROR}Error: The file $env_file does not exist. Please create it with MAC_ADDRESS and UUID variables.${NC}"
        exit 1
    fi

    # Source the file
    source "$env_file"

    # Validate MAC_ADDRESS and UUID
    if [[ -z "$MAC_ADDRESS" ]]; then
        echo -e "${ERROR}Error: MAC_ADDRESS is not defined in $env_file.${NC}"
        exit 1
    fi
    if [[ -z "$UUID" ]]; then
        echo -e "${ERROR}Error: UUID is not defined in $env_file.${NC}"
        exit 1
    fi

    echo -e "${INFO}Loaded MAC_ADDRESS: $MAC_ADDRESS${NC}"
    echo -e "${INFO}Loaded UUID: $UUID${NC}"
}

# Load identifiers
load_device_identifiers

# Get the parameters with validation
device_name=$(get_non_empty_input "Enter device_name: ")

# Create a directory for this device's configuration
device_dir="./$device_name"
if [ ! -d "$device_dir" ]; then
    mkdir "$device_dir"
    echo -e "${INFO}Created directory for $device_name at $device_dir${NC}"
fi

# Step 1: Create the Dockerfile
echo -e "${INFO}Creating the Dockerfile...${NC}"
cat << 'EOL' > "$device_dir/Dockerfile"
FROM ubuntu:latest
WORKDIR /app
RUN apt-get update && apt-get install -y bash curl jq make gcc bzip2 lbzip2 vim git lz4 telnet build-essential net-tools wget tcpdump systemd dbus iptables iproute2 nano
RUN curl -L https://github.com/Impa-Ventures/coa-launch-binaries/raw/main/linux/amd64/compute/launcher -o launcher && \
    curl -L https://github.com/Impa-Ventures/coa-launch-binaries/raw/main/linux/amd64/compute/worker -o worker
RUN chmod +x ./launcher && chmod +x ./worker
CMD ["/bin/bash", "-c", "exec /bin/bash"]
EOL

# Step 4: Write the UUID to a file
fake_product_uuid_file="$device_dir/fake_uuid.txt"
if [ ! -f "$fake_product_uuid_file" ]; then
    echo "$UUID" > "$fake_product_uuid_file"
fi

# Step 5: Use the provided MAC address
echo -e "${INFO}Using predefined MAC address: $MAC_ADDRESS${NC}"

# Convert device_name to lowercase for the Docker image name
device_name_lower=$(echo "$device_name" | tr '[:upper:]' '[:lower:]')

# Step 6: Build the Docker image specific to this device
echo -e "${INFO}Building the Docker image 'alliance_games_docker_$device_name_lower'...${NC}"
docker build -t "alliance_games_docker_$device_name_lower" "$device_dir"

echo -e "${SUCCESS}Congratulations! The Docker container '${device_name}' has been successfully set up with predefined identifiers.${NC}"
echo -e "${WARNING}Now copy and paste the 3rd command from AG Device Initialization board in the following command prompt...${NC}"

# Step 7: Run the Docker container
docker run -it --mac-address="$MAC_ADDRESS" -v "$fake_product_uuid_file:/sys/class/dmi/id/product_uuid" --name="$device_name" "alliance_games_docker_$device_name_lower"
