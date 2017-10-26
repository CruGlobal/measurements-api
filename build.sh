#!/bin/bash

docker build \
    --build-arg SIDEKIQ_CREDS=$SIDEKIQ_CREDS \
    -t 056154071827.dkr.ecr.us-east-1.amazonaws.com/measurements-api:$ENVIRONMENT-$BUILD_NUMBER .
