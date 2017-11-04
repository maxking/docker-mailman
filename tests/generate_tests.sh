#!/bin/sh


if [ "$TRAVIS_EVENT_TYPE" = "cron" ] || [ ! -z $DEV ] ; then
		echo "Travis event type is: $TRAVIS_EVENT_TYPE"
		echo "This is a development version build: $DEV"
		TAG="rolling"
else
		if [ "$TRAVIS_BRANCH" = "master" ]; then
				TAG="latest"
		else
				TAG="$TRAVIS_BRANCH"
		fi
fi


cat > docker-test.yaml <<EOF
version: '2'

services:
  mailman-core:
    image: maxking/mailman-core:$TAG

  mailman-web:
    image: maxking/mailman-web:$TAG
    environment:
    - SECRET_KEY=abcdefghijklmnopqrstuv
EOF
