#!/bin/bash

echo "Git update the local code ..."
git pull

echo "Turn down the docker containers ..."
docker compose down

echo "Remove knowledge library ragflow image ..."
docker rmi infiniflow/ragflow:dev

echo "Building the knowledge library ragflow image..."
docker compose -f docker-compose-gpu.yml build ragflow

echo "Turn on the docker containers ..."
docker compose -f docker-compose-gpu.yml up -d

echo "Containers started successfully."

