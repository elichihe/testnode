# Use a base image with an updated GLIBC version
FROM ubuntu:latest

# Update and install necessary packages
RUN apt-get update && \
    apt-get install -y curl bash

# Set a working directory (optional)
WORKDIR /app

# Copy the environment file into the container
COPY icn.env /app/icn.env

# Export the environment variables from icn.env
RUN bash -c "source /app/icn.env && echo 'ptvkey=$ptvkey'"

# Run the ICN installation command using the ptvkey from icn.env
CMD ["bash", "-c", "source /app/icn.env && curl -o- https://console.icn.global/downloads/install/start.sh | bash -s -- -p $ptvkey"]