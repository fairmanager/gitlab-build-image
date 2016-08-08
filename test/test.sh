#!/bin/sh

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
	fairmanager/strider-docker-slave:latest < ./test/test.json

echo "No actual comparison happened here. This test currently always succeeds."
