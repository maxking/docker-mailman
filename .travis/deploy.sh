#! /bin/bash

deploy() {
	REG_URL=${REGISTRY}_URL
	REG_USER=${REGISTRY}_USER
	REG_PASS=${REGISTRY}_PASS
	docker login -u ${!REG_USER} -p ${!REG_PASS} ${!REG_URL}
	docker push ${!REG_URL}/maxking/mailman-web
	docker push ${!REG_URL}/maxking/mailman-core
}

if [ ! "$BRANCH" = "master" ] && [ "$PULL_REQUEST" ]; then
	echo "Deploy only from master branch. This is $TRAVIS_BRANCH"
	exit 0
fi

deploy
