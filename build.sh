#!/bin/bash

set -ex

# Since all the dockerfiles now require buildkit features.
export DOCKER_BUILDKIT=1

# Set the default value of BUILD_ROLLING to no.
export BUILD_ROLLING="${1:-no}"

DOCKER=docker

# The following variables can be overridden using env-variables

# Set tag namespace (i.e. ghcr.io/<org> for github package registry)
TAG_NS="${TAG_NS:-maxking}"
# Set default platforms to build
BUILD_PLATFORM="${BUILD_PLATFORM:-linux/arm64/v8,linux/amd64}"
# Platform to load into docker after build
# Can only load one platform, should match host
# mostly used: linux/amd64 and linux/arm64
CURRENT_PLATFORM="${CURRENT_PLATFORM:-linux/amd64}"
# set env-var PUSH to yes to push to registry
PUSH="${PUSH:-no}"

build() {
    if [ "$PUSH" = "yes" ]; then
        $DOCKER buildx build --platform $BUILD_PLATFORM $@ --push
    else
        $DOCKER buildx build --platform $BUILD_PLATFORM $@
    fi
    $DOCKER buildx build --platform $CURRENT_PLATFORM $@ --load
}

# Check if the builder with name "multiarch" exists, if not create it
if ! docker buildx ls | grep -q multiarch; then
  docker buildx create --name multiarch --driver docker-container --use
fi

if [ "$BUILD_ROLLING" = "yes" ]; then
    echo "Building rolling releases..."
    # Build the mailman-core image.
    build -f core/Dockerfile.dev \
            --label version.git_commit="$COMMIT_ID" \
            -t $TAG_NS/mailman-core:rolling core/

    # Build the mailman-web image.
    build -f web/Dockerfile.dev \
            --label version.git_commit="$COMMIT_ID" \
            -t $TAG_NS/mailman-web:rolling web/

    # build the postorius image.
    build -f postorius/Dockerfile.dev\
            --label version.git_commit="$COMMIT_ID"\
            -t $TAG_NS/postorius:rolling postorius/
else
    echo "Building stable releases..."
    # Build the stable releases.
    build --tag $TAG_NS/mailman-core:rolling core/
    build --tag $TAG_NS/mailman-web:rolling web/ 
    build --tag $TAG_NS/postorius:rolling postorius/ 
fi
