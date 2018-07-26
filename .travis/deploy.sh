#! /bin/bash

set -e

USER=maxking

deploy() {
	URL="$1"
	TAG="$2"
	PASSWORD="$3"
	# Tag the containers correctly.
	docker tag maxking/mailman-core:rolling "$URL/maxking/mailman-core:$TAG"
	docker tag maxking/mailman-web:rolling  "$URL/maxking/mailman-web:$TAG"
	docker tag maxking/postorius:rolling "$URL/maxking/postorius:$TAG"
	# Login to the registry and push.
	docker login -u $USER -p $PASSWORD $URL
	docker push "$URL/maxking/mailman-web:$TAG"
	docker push "$URL/maxking/mailman-core:$TAG"
	docker push "$URL/maxking/postorius:$TAG"
}

if [ ! "$BRANCH" = "master" ] && [ "$PULL_REQUEST" ]; then
	echo "Deploy only from master branch. This is $TRAVIS_BRANCH"
	exit 0
fi

deploy "quay.io" "rolling" "$DOCKER_PASSWORD"
deploy "docker.io" "rolling" "$QUAY_PASSWORD"
