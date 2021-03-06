#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/../../config.sh
cd $DIR

DOCKER_TAG="default-service"
DOCKER_NAME="default-service-dev"

# Attempt to build the golang binary before building docker image (fail fast)
go build $DIR/*.go
if [ $? -ne 0 ]; then
  exit $?
fi

# Cleanup old docker containers for given service
docker stop ${DOCKER_NAME} 2>&1 > /dev/null
OLD_DOCKER=$(docker ps -a --filter "name=$DOCKER_TAG" | awk '{if(NR>1) print $1 }')
if [ -n "$OLD_DOCKER" ]; then
  docker rm $OLD_DOCKER
fi

# Deploy dev docker instance for service
docker build -t ${DOCKER_TAG} $DIR
if [ $? -ne 0 ]; then
  echo "Failed to build service ${DOCKER_TAG}'s docker instance"
  exit $?
fi

docker run \
  -i -t -d \
  -p 8080:8080 \
  -e GOOGLE_APPLICATION_CREDENTIALS="/go/src/github.com/cobookman/collabdraw/services/default/service-account.json" \
  -e GCLOUD_PROJECT_ID="$PROJECT_ID" \
  -e GCLOUD_PROJECT="$PROJECT_ID" \
  --name $DOCKER_NAME \
  $DOCKER_TAG

