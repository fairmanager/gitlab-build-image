#!/bin/sh

# Spawns a shell inside the Docker image.
# Allows you to inspect the environment.

echo "Building image..."
docker build \
	--tag strider-docker-slave:test .

echo "Spawning shell...";
docker run \
	--interactive --tty --rm \
	strider-docker-slave:test bash

echo "Cleaning up..."
docker rmi strider-docker-slave:test 2>&1 > /dev/null
