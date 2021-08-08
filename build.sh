#!/bin/bash

set -ex

DOCKER=docker

# Set the env variable to later test this release before it is deployed.
if [ "$1" = "dev" ]; then
    export DEV=true
fi

REG_URL=${REGISTRY}_URL

if [ "$EVENT_TYPE" = "cron" ]  || [ "$DEV" = "true" ]; then
    python3 -m venv venv
    source venv/bin/activate
    pip install python-gitlab
    # Get the latest commit for repositories and set their reference values to be
    # used in the development builds.
    CORE_REF=$(python get_latest_ref.py mailman/mailman)
    CLIENT_REF=$(python get_latest_ref.py mailman/mailmanclient)
    POSTORIUS_REF=$(python get_latest_ref.py mailman/postorius)
    HYPERKITTY_REF=$(python get_latest_ref.py mailman/hyperkitty)
    DJ_MM3_REF=$(python get_latest_ref.py mailman/django-mailman3)
    MM3_HK_REF=$(python get_latest_ref.py mailman/mailman-hyperkitty)

	for value in amd64 arm32v7 arm64v8
	do
		# Build the mailman-core image.
		$DOCKER build -f core/Dockerfile.dev \
	        --build-arg ARCH=$value \
            --build-arg CORE_REF=$CORE_REF \
            --build-arg MM3_HK_REF=$MM3_HK_REF \
            --label version.core="$CORE_REF" \
            --label version.mm3-hk="$MM3_HK_REF" \
            --label version.git_commit="$COMMIT_ID" \
	        -t maxking/mailman-core:rolling-$value core/

		# Build the mailman-web image.
		$DOCKER build -f web/Dockerfile.dev \
	        --build-arg ARCH=$value \
            --label version.git_commit="$COMMIT_ID" \
            --label version.postorius="$POSTORIUS_REF" \
            --label version.hyperkitty="$HYPERKITTY_REF" \
            --label version.client="$CLIENT_REF" \
            --label version.dj-mm3="$DJ_MM3_REF" \
            --build-arg POSTORIUS_REF=$POSTORIUS_REF \
            --build-arg CLIENT_REF=$CLIENT_REF \
            --build-arg HYPERKITTY_REF=$HYPERKITTY_REF \
            --build-arg DJ_MM3_REF=$DJ_MM3_REF \
	        -t maxking/mailman-web:rolling-$value web/

		$DOCKER build -f postorius/Dockerfile.dev\
	        --build-arg ARCH=$value \
			--label version.git_commit="$COMMIT_ID"\
            --label version.postorius="$POSTORIUS_REF" \
            --label version.client="$CLIENT_REF" \
            --label version.dj-mm3="$DJ_MM3_REF" \
            --build-arg POSTORIUS_REF=$POSTORIUS_REF \
            --build-arg CLIENT_REF=$CLIENT_REF \
            --build-arg DJ_MM3_REF=$DJ_MM3_REF \
	        -t maxking/postorius:rolling-$value postorius/
	done
else
	for value in amd64 arm32v7 arm64v8
	do
		# Do the normal building process.
		$DOCKER build \
		--build-arg ARCH=$value \
		-t maxking/mailman-core:rolling-$value core/
		$DOCKER build \
		--build-arg ARCH=$value \
		-t maxking/mailman-web:rolling-$value web/
		$DOCKER build \
		--build-arg ARCH=$value \
		-t maxking/postorius:rolling-$value postorius/
	done
fi

docker manifest create \
	maxking/mailman-core:rolling \
	--amend maxking/mailman-core:rolling-amd64 \
	--amend maxking/mailman-core:rolling-arm32v7 \
	--amend maxking/mailman-core:rolling-arm64v8

docker manifest create \
	maxking/mailman-web:rolling \
	--amend maxking/mailman-web:rolling-amd64 \
	--amend maxking/mailman-web:rolling-arm32v7 \
	--amend maxking/mailman-web:rolling-arm64v8

docker manifest create \
	maxking/postorius:rolling \
	--amend maxking/postorius:rolling-amd64 \
	--amend maxking/postorius:rolling-arm32v7 \
	--amend maxking/postorius:rolling-arm64v8