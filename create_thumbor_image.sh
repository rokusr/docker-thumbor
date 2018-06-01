#!/bin/bash
if [ -z "$THUMBOR_VERSION" ]
then
  THUMBOR_VERSION="6.3.0"
fi

# git clone git@github.com:rokusr/docker-thumbor.git
# cd docker-thumbor

docker network create builder

echo "THUMBOR VERSION: $THUMBOR_VERSION"

echo "--> Wheelhousing requirements in /wheelhouse"
docker build -t test/builder -f Dockerfile.build .
mkdir -p wheelhouse
docker run --rm -v "$(pwd)"/wheelhouse:/wheelhouse test/builder

echo "Launch Pypiserver"
docker run -d --rm --network builder -v "$(pwd)"/wheelhouse:/data/packages --name pypiserver jcsaaddupuy/pypiserver
docker ps -a

echo "--> BUILDING apsl/thumbor"
docker build --network builder -f thumbor/Dockerfile -t sr/thumbor thumbor/
echo "--> TAGGING sr/thumbor:$THUMBOR_VERSION"
docker tag sr/thumbor sr/thumbor:$THUMBOR_VERSION
echo "--> TAGGING sr/thumbor:latest"
docker tag sr/thumbor sr/thumbor:latest

echo "--> CLEANUP for pypiserver and builder network"
docker rm -f pypiserver
docker network rm builder
