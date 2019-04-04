#!/bin/bash

docker build \
    --build-arg SIDEKIQ_CREDS=$SIDEKIQ_CREDS \
    --build-arg SECRET_KEY_BASE=$SECRET_KEY_BASE \
    -t 056154071827.dkr.ecr.us-east-1.amazonaws.com/measurements-api:$ENVIRONMENT-$BUILD_NUMBER .
