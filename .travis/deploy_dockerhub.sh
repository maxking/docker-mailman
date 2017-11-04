#!/bin/bash

function deploy {
		docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS
		docker push maxking/mailman-web:$1
		docker push maxking/mailman-core:$1
}


if [ "$TRAVIS_EVENT_TYPE" = "cron" ]; then
		deploy "rolling"
elif [ "$TRAVIS_BRANCH" = "master" ]; then
		deploy "latest"
else
		# If the branch isn't master and this was not a cron job, no need to deploy.
		echo "TRAVIS_EVENT_TYPE = $TRAVIS_EVENT_TYPE, TRAVIS_BRANCH = $TRAVIS_BRANCH"
		exit 0
fi
