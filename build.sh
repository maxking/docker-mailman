#!/bin/bash

set -ex

# Set the default value of BUILD_ROLLING to no.
export BUILD_ROLLING="${1:-no}"

DOCKER=docker

if [ "$BUILD_ROLLING" = "yes" ]; then
    echo "Building rolling releases..."
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

    # Build the mailman-core image.
    $DOCKER build -f core/Dockerfile.dev \
            --build-arg CORE_REF=$CORE_REF \
            --build-arg MM3_HK_REF=$MM3_HK_REF \
            --label version.core="$CORE_REF" \
            --label version.mm3-hk="$MM3_HK_REF" \
            --label version.git_commit="$COMMIT_ID" \
            -t maxking/mailman-core:rolling core/ &

    # Build the mailman-web image.
    $DOCKER build -f web/Dockerfile.dev \
            --label version.git_commit="$COMMIT_ID" \
            --label version.postorius="$POSTORIUS_REF" \
            --label version.hyperkitty="$HYPERKITTY_REF" \
            --label version.client="$CLIENT_REF" \
            --label version.dj-mm3="$DJ_MM3_REF" \
            --build-arg POSTORIUS_REF=$POSTORIUS_REF \
            --build-arg CLIENT_REF=$CLIENT_REF \
            --build-arg HYPERKITTY_REF=$HYPERKITTY_REF \
            --build-arg DJ_MM3_REF=$DJ_MM3_REF \
            -t maxking/mailman-web:rolling web/ &

    # build the postorius image.
    $DOCKER build -f postorius/Dockerfile.dev\
			--label version.git_commit="$COMMIT_ID"\
            --label version.postorius="$POSTORIUS_REF" \
            --label version.client="$CLIENT_REF" \
            --label version.dj-mm3="$DJ_MM3_REF" \
            --build-arg POSTORIUS_REF=$POSTORIUS_REF \
            --build-arg CLIENT_REF=$CLIENT_REF \
            --build-arg DJ_MM3_REF=$DJ_MM3_REF \
			-t maxking/postorius:rolling postorius/ &
else
    echo "Building stable releases..."
    # Build the stable releases.
    $DOCKER build -t maxking/mailman-core:rolling core/ &
    $DOCKER build -t maxking/mailman-web:rolling web/ &
    $DOCKER build -t maxking/postorius:rolling postorius/ &
fi

wait
