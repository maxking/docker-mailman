#!/bin/sh


if [ "$EVENT_TYPE" = "cron" ] || [ ! -z $DEV ] ; then
		echo "Event type is: $EVENT_TYPE"
		echo "This is a development version build: $DEV"
		TAG="rolling"
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
