#!/bin/bash

# Navigate to the determined directory
cd /home/bizon/determined

# Start Determined agent container
docker run -d --restart unless-stopped \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD"/agent.yaml:/etc/determined/agent.yaml \
    --gpus all \
    --network host \
    determinedai/determined-agent:0.32.1
