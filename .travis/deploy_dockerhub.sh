#!/bin/sh



if [ "$TRAVIS_EVENT_TYPE" = "cron" ] || [ ! -z $DEV ] ; then
		TAG="rolling"
elif [ "$TRAVIS_BRANCH" = "master" ]; then
		TAG="latest"
else
		# If the branch isn't master and this was not a cron job, no need to deploy.
		exit 0
fi


docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS
docker push maxking/mailman-web:$TAG
docker push maxking/mailman-core$TAG
