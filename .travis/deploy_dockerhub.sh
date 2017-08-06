#!/bin/sh

if [[ "$TRAVIS_BRANCH" == "master" ]]
then
	docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS
	docker push maxking/mailman-web
	docker push maxking/mailman-core
else
	echo "Non-master branch aren't pushed to DockerHub..."
fi
