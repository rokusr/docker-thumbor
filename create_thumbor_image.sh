#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo "Usage: .create_thumbor_image.sh -t thumbor-version -p profile";
    exit 0
fi

while getopts "t:p:h" option; do
    case "${option}"
        in
        t) THUMBOR_VERSION=${OPTARG};;
        p) PROFILE=${OPTARG};;
        h ) echo "Usage: .create_thumbor_image.sh -t thumbor-version -p profile"; exit 0;;
        \? ) echo "Usage: .create_thumbor_image.sh -t thumbor-version -p profile"; exit 0;;
    esac
done

if [ -z "$THUMBOR_VERSION" ]
then
  THUMBOR_VERSION="6.3.0"
fi

if [ -z "$PROFILE" ]
then
  echo "PROFILE not provided. Exiting!"
  exit 1
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

echo "--> PUSHING sr/thumbor:latest to 638782101961.dkr.ecr.us-east-1.amazonaws.com/sr/thumbor:latest"
eval $( echo `aws ecr --profile $PROFILE get-login --no-include-email --region us-east-1` )
docker tag sr/thumbor:latest 638782101961.dkr.ecr.us-east-1.amazonaws.com/sr/thumbor:latest
docker push 638782101961.dkr.ecr.us-east-1.amazonaws.com/sr/thumbor:latest
