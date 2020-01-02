#! /bin/bash
set -e


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

function wait_for_mysql () {
	# Check if MySQL is up and accepting connections.
	HOSTNAME=$(python3 <<EOF
try:
    from urllib.parse import urlparse
except ImportError:
    from urlparse import urlparse
o = urlparse('$DATABASE_URL')
print(o.hostname)
EOF
)
	until mysqladmin ping --host "$HOSTNAME" --silent; do
		>&2 echo "MySQL is unavailable - sleeping"
		sleep 1
	done
	>&2 echo "MySQL is up - continuing"
}


function check_or_create () {
	# Check if the path exists, if not, create the directory.
	if [[ ! -e dir ]]; then
		echo "$1 does not exist, creating ..."
		mkdir "$1"
	fi
}

# function postgres_ready(){
# python << END
# import sys
# import psycopg2
# try:
#     conn = psycopg2.connect(dbname="$POSTGRES_DB", user="$POSTGRES_USER", password="$POSTGRES_PASSWORD", host="postgres")
# except psycopg2.OperationalError:
#     sys.exit(-1)
# sys.exit(0)
# END
# }

# Check if $SECRET_KEY is defined, if not, bail out.
if [[ ! -v SECRET_KEY ]]; then
	echo "SECRET_KEY is not defined. Aborting."
	exit 1
fi

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

if [[ ! -v DATABASE_URL ]]; then
	echo "DATABASE_URL is not defined. Using sqlite database..."
	export DATABASE_URL=sqlite://mailmanweb.db
	export DATABASE_TYPE='sqlite'
fi

if [[ "$DATABASE_TYPE" = 'postgres' ]]
then
	wait_for_postgres
elif [[ "$DATABASE_TYPE" = 'mysql' ]]
then
	wait_for_mysql
fi

# Check if we are in the correct directory before running commands.
if [[ ! $(pwd) == '/opt/mailman-web' ]]; then
	echo "Running in the wrong directory...switching to /opt/mailman-web"
	cd /opt/mailman-web
fi

# Check if the logs directory is setup.
if [[ ! -e /opt/mailman-web-data/logs/mailmanweb.log ]]; then
	echo "Creating log file for mailman web"
	mkdir -p /opt/mailman-web-data/logs/
	touch /opt/mailman-web-data/logs/mailmanweb.log
fi

if [[ ! -e /opt/mailman-web-data/logs/uwsgi.log ]]; then
	echo "Creating log file for uwsgi.."
	touch /opt/mailman-web-data/logs/uwsgi.log
fi

# Check if the settings_local.py file exists, if yes, copy it too.
if [[ -e /opt/mailman-web-data/settings_local.py ]]; then
	echo "Copying settings_local.py ..."
	cp /opt/mailman-web-data/settings_local.py /opt/mailman-web/settings_local.py
	chown mailman:mailman /opt/mailman-web/settings_local.py
else
	echo "settings_local.py not found, it is highly recommended that you provide one"
	echo "Using default configuration to run."
fi

# Collect static for the django installation.
python3 manage.py collectstatic --noinput

# Migrate all the data to the database if this is a new installation, otherwise
# this command will upgrade the database.
python3 manage.py migrate

# If MAILMAN_ADMIN_USER and MAILMAN_ADMIN_EMAIL is defined create a new
# superuser for Django. There is no password setup so it can't login yet unless
# the password is reset.
if [[ -v MAILMAN_ADMIN_USER ]] && [[ -v MAILMAN_ADMIN_EMAIL ]];
then
	echo "Creating admin user $MAILMAN_ADMIN_USER ..."
	python3 manage.py createsuperuser --noinput --username "$MAILMAN_ADMIN_USER"\
		   --email "$MAILMAN_ADMIN_EMAIL" 2> /dev/null || \
		echo "Superuser $MAILMAN_ADMIN_USER already exists"
fi

# If SERVE_FROM_DOMAIN is defined then rename the default `example.com`
# domain to the defined domain.
if [[ -v SERVE_FROM_DOMAIN ]];
then
	echo "Setting $SERVE_FROM_DOMAIN as the default domain ..."
	python3 manage.py shell -c \
	"from django.contrib.sites.models import Site; Site.objects.filter(domain='example.com').update(domain='$SERVE_FROM_DOMAIN', name='$SERVE_FROM_DOMAIN')"
fi

# Create a mailman user with the specific UID and GID and do not create home
# directory for it. Also chown the logs directory to write the files.
chown mailman:mailman /opt/mailman-web-data -R

exec $@
