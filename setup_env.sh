# Script to setup environment variables.

set -ex

set_var () {
	echo $1=$2 >> $BASH_ENV
	export $1=$2
}

setup_env () {
	CI_NAME=$1
	# Set the current branch name.
	BRANCH_NAME=${CI_NAME}_BRANCH
    set_var BRANCH ${!BRANCH_NAME}
}


if [ "$TRAVIS" ]; then
	# Set environments picked up from Circle CI.
	set_var EVENT_TYPE "$TRAVIS_EVENT_TYPE"
	set_var COMMIT_ID $TRAVIS_COMMIT
	# Setup some generic environment vars.
	setup_env TRAVIS
elif [ "$CIRCLECI" ]; then
	# Set environments picked up from Circle CI.
	set_var EVENT_TYPE "push"
	set_var COMMIT_ID $CIRCLE_SHA1
	# Setup some generic environment vars.
	setup_env CIRCLE
fi

if [ "$BRANCH" = "master" ]; then
	set_var TAG "latest"
else
	set_var TAG "$BRANCH"
fi

set_var REG_URL ${REGISTRY}_URL
