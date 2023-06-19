#! /bin/bash
set -e

function wait_for_postgres () {
	# Check if the postgres database is up and accepting connections before
	# moving forward.
	# TODO: Use python3's psycopg2 module to do this in python3 instead of
	# installing postgres-client in the image.
	until psql -P pager=off $DATABASE_URL -c '\l'; do
		>&2 echo "Postgres is unavailable - sleeping"
		sleep 1
	done
	>&2 echo "Postgres is up - continuing"
}

function wait_for_mysql () {
	# Check if MySQL is up and accepting connections.
	readarray -d' ' -t ENDPOINT <<< $(python3 -c "from urllib.parse import urlparse; o = urlparse('$DATABASE_URL'); print('%s %s' % (o.hostname, o.port if o.port else '3306'));")
	until mysqladmin ping --host ${ENDPOINT[0]} --port ${ENDPOINT[1]} --silent; do
		>&2 echo "MySQL is unavailable - sleeping"
		sleep 1
	done
	>&2 echo "MySQL is up - continuing"
}

# Empty the config file.
echo "# This file is autogenerated at container startup." > /etc/mailman.cfg

# Check if $MM_HOSTNAME is set, if not, set it to the value returned by
# `hostname -i` command to set it to whatever IP address is assigned to the
# container.
if [[ ! -v MM_HOSTNAME ]]; then
	export MM_HOSTNAME=`hostname -i`
fi

# SMTP_HOST defaults to the gateway
if [[ ! -v SMTP_HOST ]]; then
	export SMTP_HOST=$(/sbin/ip route | awk '/default/ { print $3 }')
	echo "SMTP_HOST not specified, using the gateway ($SMTP_HOST) as default"
fi

if [[ ! -v SMTP_PORT ]]; then
	export SMTP_PORT=25
fi

# Check if REST port, username, and password are set, if not, set them
# to default values.
if [[ ! -v MAILMAN_REST_PORT ]]; then
	export MAILMAN_REST_PORT='8001'
fi

if [[ ! -v MAILMAN_REST_USER ]]; then
	export MAILMAN_REST_USER='restadmin'
fi

if [[ ! -v MAILMAN_REST_PASSWORD ]]; then
	export MAILMAN_REST_PASSWORD='restpass'
fi

function setup_database () {
	if [[ ! -v DATABASE_URL ]]
	then
		echo "Environment variable DATABASE_URL should be defined..."
		exit 1
	fi

	# Translate mysql:// urls to mysql+mysql:// backend:
	if [[ "$DATABASE_URL" == mysql://* ]]; then
		DATABASE_URL="mysql+pymysql://${DATABASE_URL:8}"
		echo "Database URL was automatically rewritten to: $DATABASE_URL"
	fi

	# If DATABASE_CLASS is not set, guess it for common databases:
	if [ -z "$DATABASE_CLASS" ]; then
		if [[ ("$DATABASE_URL" == mysql:*) ||
				("$DATABASE_URL" == mysql+*) ]]; then
			DATABASE_CLASS=mailman.database.mysql.MySQLDatabase
		fi
		if [[ ("$DATABASE_URL" == postgres:*) ||
				("$DATABASE_URL" == postgres+*) ]]; then
			DATABASE_CLASS=mailman.database.postgresql.PostgreSQLDatabase
		fi
	fi

	cat >> /etc/mailman.cfg <<EOF
[database]
class: $DATABASE_CLASS
url: $DATABASE_URL
EOF
}


# Check if $DATABASE_URL is defined, if not, use a standard sqlite database.
#
# If the $DATABASE_URL is defined and is postgres, check if it is available
# yet. Do not start the container before the postgresql boots up.
#
# TODO: If the $DATABASE_URL is defined and is mysql, check if the database is
# available before the container boots up.
#
# TODO: Check the database type and detect if it is up based on that. For now,
# assume that postgres is being used if DATABASE_URL is defined.
if [[ ! -v DATABASE_URL ]]; then
	echo "DATABASE_URL is not defined. Using sqlite database..."
else
	setup_database
fi


if [[ "$DATABASE_TYPE" = 'postgres' ]]
then
	wait_for_postgres
elif [[ "$DATABASE_TYPE" = 'mysql' ]]
then
	wait_for_mysql
fi

# Generate a basic mailman.cfg.
cat >> /etc/mailman.cfg << EOF
[runner.retry]
sleep_time: 10s

[webservice]
hostname: $MM_HOSTNAME
port: $MAILMAN_REST_PORT
admin_user: $MAILMAN_REST_USER
admin_pass: $MAILMAN_REST_PASSWORD
configuration: /etc/gunicorn.cfg

EOF

# Generate a basic gunicorn.cfg.
SITE_DIR=$(python3 -c 'import site; print(site.getsitepackages()[0])')
cp "${SITE_DIR}/mailman/config/gunicorn.cfg" /etc/gunicorn.cfg

# Generate a basic configuration to use exim
cat > /tmp/exim-mailman.cfg <<EOF
[mta]
incoming: mailman.mta.exim4.LMTP
outgoing: mailman.mta.deliver.deliver
lmtp_host: $MM_HOSTNAME
lmtp_port: 8024
smtp_host: $SMTP_HOST
smtp_port: $SMTP_PORT
smtp_user: $SMTP_HOST_USER
smtp_pass: $SMTP_HOST_PASSWORD
configuration: python:mailman.config.exim4

EOF

cat > /etc/postfix-mailman.cfg << EOF
[postfix]
transport_file_type: regex
# While in regex mode, postmap_command is never used, a placeholder
# is added here so that it doesn't break anything.
postmap_command: true
EOF

# Generate a basic configuration to use postfix.
cat > /tmp/postfix-mailman.cfg <<EOF
[mta]
incoming: mailman.mta.postfix.LMTP
outgoing: mailman.mta.deliver.deliver
lmtp_host: $MM_HOSTNAME
lmtp_port: 8024
smtp_host: $SMTP_HOST
smtp_port: $SMTP_PORT
smtp_user: $SMTP_HOST_USER
smtp_pass: $SMTP_HOST_PASSWORD
configuration: /etc/postfix-mailman.cfg

EOF

if [ "$MTA" == "exim" ]
then
	echo "Using Exim configuration"
	cat /tmp/exim-mailman.cfg >> /etc/mailman.cfg
elif [ "$MTA" == "postfix" ]
then
	echo "Using Postfix configuration"
	cat /tmp/postfix-mailman.cfg >> /etc/mailman.cfg
else
	echo "No MTA environment variable found, defaulting to Exim"
	cat /tmp/exim-mailman.cfg >> /etc/mailman.cfg
fi

rm -f /tmp/{postfix,exim}-mailman.cfg

if [[ -e /opt/mailman/mailman-extra.cfg ]]
then
	echo "Found configuration file at /opt/mailman/mailman-extra.cfg"
	cat /opt/mailman/mailman-extra.cfg >> /etc/mailman.cfg
fi

if [[ -e /opt/mailman/gunicorn-extra.cfg ]]
then
       echo "Found [webserver] configuration file at /opt/mailman/gunicorn-extra.cfg"
       cat /opt/mailman/gunicorn-extra.cfg > /etc/gunicorn.cfg
fi

if [[ -v HYPERKITTY_API_KEY ]]; then

echo "HYPERKITTY_API_KEY found, setting up HyperKitty archiver..."

cat >> /etc/mailman.cfg << EOF
[archiver.hyperkitty]
class: mailman_hyperkitty.Archiver
enable: yes
configuration: /etc/mailman-hyperkitty.cfg

EOF

if [[ ! -v HYPERKITTY_URL ]]; then
	echo "HYPERKITTY_URL not set, using the default value of http://mailman-web:8000/hyperkitty"
	export HYPERKITTY_URL="http://mailman-web:8000/hyperkitty/"
fi

# Generate a basic mailman-hyperkitty.cfg.
cat > /etc/mailman-hyperkitty.cfg <<EOF
[general]
base_url: $HYPERKITTY_URL
api_key: $HYPERKITTY_API_KEY
EOF

else

echo "HYPERKITTY_API_KEY not defined, skipping HyperKitty setup..."

fi

# Now chown the places where mailman wants to write stuff.
chown -R mailman /opt/mailman

# Generate the LMTP files for postfix if needed.
su-exec mailman mailman aliases

exec su-exec mailman "$@"
