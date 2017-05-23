#!/bin/sh

if [ "$TRAVIS_BRANCH" = "master" ]; then
    TAG="latest"
else
    TAG="$TRAVIS_BRANCH"
fi


cat > docker-test.yaml <<EOF
services:
  mailman-core:
    image:maxking/mailman-core:$TAG

  mailman-web:
    image:maxking/mailman-web:$TAG
EOF
