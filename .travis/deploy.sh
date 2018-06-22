#! /bin/bash

USER=maxking


deploy(URL, TAG, PASSWORD) {
	# Tag the containers correctly.
	docker tag maxking/mailman-core "$URL/maxking/mailman-core:$TAG"
	docker tag maxking/mailman-web  "$URL/maxking/mailman-web:$TAG"
	docker tag maxking/postorius "$URL/maxking/postorius:$TAG"
	# Login to the registry and push.
	docker login -u $USER -p ${!PASSWORD} $URL
	docker push "$URL/maxking/mailman-web:$TAG"
	docker push "$URL/maxking/mailman-core:$TAG"
	docker push "$URL/maxking/postorius:$TAG"
}

if [ ! "$BRANCH" = "master" ] && [ "$PULL_REQUEST" ]; then
	echo "Deploy only from master branch. This is $TRAVIS_BRANCH"
	exit 0
fi

deploy "quay.io" "rolling" $DOCKER_PASSWORD
deploy "docker.io" "rolling" $QUAY_PASSWORD
