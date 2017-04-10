#! /bin/bash
set -e

# Check if the master lock exists for the mailman.
# It means that that either some other mailman process is running or
# the last time mailman did not exit clean.
if [[ -e /opt/mailman/core/var/locks/master.lck ]]; then
	echo "The mailman's master lock file still exists at /opt/mailman/core/var/locks/master.lck"
	echo "Please remove the lock file before trying to run this container again."
	exit 1
fi

function wait_for_postgres () {
	# Check if the postgres database is up and accepting connections before
	# moving forward.
	# TODO: Use python's psycopg2 module to do this in python instead of
	# installing postgres-client in the image.
	until psql $DATABASE_URL -c '\l'; do
		>&2 echo "Postgres is unavailable - sleeping"
		sleep 1
	done
	>&2 echo "Postgres is up - continuing"
}


# Check if $DATABASE_URL is defined, if not, use a standard sqlite database.
#
# If the $DATABASE_URL is defined and is postgres, check if it is available
# yet. Do not start the container before the postgresql boots up.
#
# If the $DATABASE_URL is defined and is mysql, check if the database is
# available before the container boots up.
#
# TODO: Check the database type and detect if it is up based on that. For now,
# assume that postgres is being used if DATABASE_URL is defined.
if [[ ! -v DATABASES_URL ]]; then
	echo "DATABASE_URL is not defined. Using sqlite database..."
	export DATABASE_URL=sqlite:///mailman.db
	export DATABASE_TYPE='sqlite'
	export DATABASE_CLASS='mailman.database.sqlite.SQLiteDatabase'
fi


if [[ "$DATABASE_TYPE" = 'postgres' ]]
then
	wait_for_postgres
fi

# Check if $MM_HOSTNAME is set, if not, set it to a default value.
# TODO: Factor this out to a function.
if [[ ! -v MM_HOSTNAME ]]; then
	export MM_HOSTNAME=mailman-core
fi

if [[ ! -v SMTP_HOST ]]; then
	export SMTP_HOST='172.19.199.1'
fi

if [[ ! -v SMTP_PORT ]]; then
	export SMTP_PORT=25
fi

if [[ ! -d /config/ ]]; then
	mkdir /config/
fi

# Generate a basic mailman.cfg.
cat > /config/mailman.cfg <<EOF
[mta]
incoming: mailman.mta.exim4.LMTP
outgoing: mailman.mta.deliver.deliver
lmtp_host: $MM_HOSTNAME
lmtp_port: 8024
smtp_host: $SMTP_HOST
smtp_port: $SMTP_PORT
configuration: python:mailman.config.exim4

[runner.retry]
sleep_time: 10s

[webservice]
hostname: $MM_HOSTNAME

[archiver.hyperkitty]
class: mailman_hyperkitty.Archiver
enable: yes
configuration: /config/mailman-hyperkitty.cfg

[database]
class: $DATABASE_CLASS
url: $DATABASE_URL
EOF

if [[ -e /opt/mailman/mailman.cfg ]]
then
	echo "Found configuration file at /opt/mailman/mailman.cfg"
	cat /opt/mailman/mailman.cfg >> /config/mailman.cfg
fi


if [[ ! -v HYPERKITTY_API_KEY ]]; then
	echo "HYPERKITTY_API_KEY not defined, please set this environment variable..."
	echo "exiting..."
	exit 1
fi

if [[ -v HYPERKITTY_URL ]]; then
	echo "HYPERKITTY_URL not set, using the default value of http://mailman-web:8000/hyperkitty"
	export HYPERKITTY_URL="http://mailman-web:8000/hyperkitty/"
fi

# Generate a basic mailman-hyperkitty.cfg.
cat > /config/mailman-hyperkitty.cfg <<EOF
[general]
base_url: $HYPERKITTY_URL
api_key: $HYPERKITTY_API_KEY
EOF


exec "$@"
