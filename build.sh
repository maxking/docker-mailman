#!/bin/bash

set -e

# Use this script to build docker images.

if [[ "$TRAVIS" ]]
then
	if [ "$TRAVIS_BRANCH" = "master" ]; then
		CORE_TAG="latest"
		WEB_TAG="latest"
	else
		CORE_TAG="$TRAVIS_BRANCH"
		WEB_TAG="$TRAVIS_BRANCH"
	fi
else
    CORE_TAG=`cat core/VERSION`
    WEB_TAG=`cat web/VERSION`
fi

DOCKER=docker

$DOCKER build -t maxking/mailman-core:$CORE_TAG core/
$DOCKER build -t maxking/mailman-web:$WEB_TAG web/
