#!/bin/sh

if [ "$TRAVIS" ]; then
    if [ "$TRAVIS_BRANCH" = "master" ]; then
        TAG="latest"
    else
        TAG="$TRAVIS_BRANCH"
    fi
elif [ "$CIRCLECI" ]; then
    if [ "$CIRCLE_BRANCH" = "master" ]; then
        TAG="latest"
    else
        TAG="$CIRCLE_BRANCH"
    fi
fi



cat > docker-test.yaml <<EOF
version: '2.1'

services:
  mailman-core:
    image: maxking/mailman-core:$TAG
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/3.1/system"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 30s

  mailman-web:
    image: maxking/mailman-web:$TAG
    environment:
    - SECRET_KEY=abcdefghijklmnopqrstuv
EOF
