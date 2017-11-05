#!/bin/bash

set -ex

DOCKER=docker

# Set the env variable to later test this release before it is deployed.
if [ "$1" = "dev" ]; then
		export DEV=true
fi


if [ "$TRAVIS_EVENT_TYPE" = "pull_request"] && [ "$DEV" = "true"]; then
	echo "TRAVIS_EVENT_TYPE = $TRAVIS_EVENT_TYPE, DEV=$DEV"
	echo "Do not run this for pull requests."
	exit 0
fi

if [ "$TRAVIS_EVENT_TYPE" = "cron" ]  || [ "$DEV" = "true" ] ; then
		python -m pip install python-gitlab
		# Get the latest commit for repositories and set their reference values to be
		# used in the development builds.
		CORE_REF=$(python get_latest_ref.py mailman/mailman)
		CLIENT_REF=$(python get_latest_ref.py mailman/mailmanclient)
		POSTORIUS_REF=$(python get_latest_ref.py mailman/postorius)
		HYPERKITTY_REF=$(python get_latest_ref.py mailman/hyperkitty)
		DJ_MM3_REF=$(python get_latest_ref.py mailman/django-mailman3)
		MM3_HK_REF=$(python get_latest_ref.py mailman/mailman-hyperkitty)

		# Build the mailman-core image.
		$DOCKER build -f core/Dockerfile.dev \
						--build-arg CORE_REF=$CORE_REF \
						--build-arg MM3_HK_REF=$MM3_HK_REF \
						-t maxking/mailman-core:rolling core/

		# Build the mailman-web image.
		$DOCKER build -f web/Dockerfile.dev \
						--build-arg POSTORIUS_REF=$POSTORIUS_REF \
						--build-arg CLIENT_REF=$CLIENT_REF \
						--build-arg HYPERKITTY_REF=$HYPERKITTY_REF \
						--build-arg DJ_MM3_REF=$DJ_MM3_REF \
						-t maxking/mailman-web:rolling web/
else
		# Do the normal building process.
		if [ "$TRAVIS_BRANCH" = "master" ]; then
				TAG="latest"
		else
				TAG="$TRAVIS_BRANCH"
		fi

		$DOCKER build -t maxking/mailman-core:$TAG core/
		$DOCKER build -t maxking/mailman-web:$TAG web/
fi
