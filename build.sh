#!/bin/bash

set -e

# Use this script to build docker images.

if [ "$TRAVIS_BRANCH" = "master" ]; then
    TAG="latest"
else
    TAG="$TRAVIS_BRANCH"
fi

DOCKER=docker

$DOCKER build -t maxking/mailman-core:$TAG core/
$DOCKER build -t maxking/mailman-web:$TAG web/
