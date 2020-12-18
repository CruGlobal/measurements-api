#!/bin/bash
set -ev # Exit on first error, be verbose

# Debuggery
echo "TRAVIS_BRANCH is '${TRAVIS_BRANCH}' and TRAVIS_PULL_REQUEST is '${TRAVIS_PULL_REQUEST}'"

# Exit if not a push build to master
if [ "${TRAVIS_BRANCH}" != "master" ] || [ "${TRAVIS_PULL_REQUEST}" != "false" ]; then
  echo "Skipping ERD generation for this build."
  exit
fi

# setup:
openssl aes-256-cbc -K $encrypted_0f3834375050_key \
  -iv $encrypted_0f3834375050_iv \
  -in bin/deploy/erd-service-account.json.enc \
  -out bin/deploy/erd-service-account.json -d

bundle exec erd \
  --notation=bachman \
  --attributes=foreign_keys \
  --title="Measurements API ERD - generated `date +%F`" \
  --filename=doc/erd \
  --orientation=vertical \
  --exclude=`perl -00ne 'print join",",split' doc/rest_of_the_models.txt`

# Skip this, nothing exceptional about Measurements API
# bin/rails erd:exceptional_names >doc/exceptional_names.txt

gem install --no-document google_drive
ruby bin/deploy/upload_erd.rb
