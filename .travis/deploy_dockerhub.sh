#!/bin/bash

deploy () {
		docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS
		docker push maxking/mailman-web:$1
		docker push maxking/mailman-core:$1
}


if [ "$EVENT_TYPE" = "cron" ]; then
		deploy "rolling"
elif [ "$BRANCH" = "master" ]; then
		deploy "latest"
else
		# If the branch isn't master and this was not a cron job, no need to deploy.
		echo "EVENT_TYPE = $EVENT_TYPE, BRANCH = $BRANCH"
		exit 0
fi
