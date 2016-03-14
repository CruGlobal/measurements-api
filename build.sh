#!/bin/bash

bundle install --path vendor/bundle
rc=$?
if [ $rc -ne 0 ]; then
  echo -e "Bundle install failed"
  exit $rc
fi

bundle clean &&
docker build -t cruglobal/$PROJECT_NAME:$GIT_COMMIT-$BUILD_NUMBER .
