#!/bin/sh

echo "Building image..."
docker build \
	--tag strider-docker-slave:test .

echo ""
echo "Running tests..."
echo "Expected output:"
echo "{\"event\":\"stderr\",\"data\":\"+ echo hello\\n\"}"
echo "{\"event\":\"stdout\",\"data\":\"hello\\n\"}"
echo "{\"code\":0,\"event\":\"exit\"}"
echo ""
echo "Actual output:"

docker run \
	--interactive --attach stdout \
	--rm \
	strider-docker-slave:test < ./test/test.json

echo ""
echo "Cleaning up..."
docker rmi strider-docker-slave:test 2>&1 > /dev/null
