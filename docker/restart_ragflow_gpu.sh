#!/bin/bash

echo "Turn down the docker containers ..."
docker compose down

#echo "Remove knowledge library ragflow image ..."
#docker rmi infiniflow/ragflow:v0.19.0-slim

echo "Turn on the docker containers with GPU ..."
docker compose -f docker-compose-gpu.yml up -d

echo "Containers started successfully."

