#!/bin/bash

docker build \
    --build-arg SIDEKIQ_CREDS=$SIDEKIQ_CREDS \
    --build-arg SECRET_KEY_BASE=$SECRET_KEY_BASE \
    --build-arg DD_API_KEY=$DD_API_KEY \
    -t 056154071827.dkr.ecr.us-east-1.amazonaws.com/measurements-api:$ENVIRONMENT-$BUILD_NUMBER .
