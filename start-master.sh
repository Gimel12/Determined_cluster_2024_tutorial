#!/bin/bash

# Navigate to the determined directory
cd /home/bizon/determined

# Start PostgreSQL container
docker run -d --restart unless-stopped \
    --name determined-db \
    -p 5432:5432 \
    -v determined_db:/var/lib/postgresql/data \
    -e POSTGRES_DB=determined \
    -e POSTGRES_PASSWORD=root \
    postgres:10

# Start Determined master container
docker run -d --restart unless-stopped \
    -v "$PWD"/master.yaml:/etc/determined/master.yaml \
    --network host
    determinedai/determined-master:0.32.1
