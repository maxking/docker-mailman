#! /bin/bash
set -e

# Check if the database is available yet. Do not start the container before the
# postgresql boots up.
until psql $DATABASE_URL -c '\l'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - continuing"

# Check if we are in the correct directory before running commands.
if [[ ! $(pwd) == '/opt/mailman-web' ]]; then
	echo "Running in the wrong directory...switching to /opt/mailman-web"
	cd /opt/mailman-web
fi

# Check if the logs directory is setup.

if [[ ! -e /opt/mailman-web-data/logs/mailmanweb.log ]]; then
	echo "Create log file..."
	mkdir -p /opt/mailman-web-data/logs/
	touch /opt/mailman-web-data/logs/mailmanweb.log
fi


# Check if the settings_local.py file exists, if yes, copy it too.
if [[ -e /opt/mailman-web-data/settings_local.py ]]; then
	echo "Copying settings_local.py ..."
	cp /opt/mailman-web-data/settings_local.py /opt/mailman-web/settings_local.py
else
	echo "settings_local.py not found, it is highly recommended that you provide one/"
	echo "Using default configuration to run."
fi

# Collect static for the django installation.
python manage.py collectstatic --noinput

# Migrate all the data to the database if this is a new installation, otherwise
# this command will upgrade the database.
python manage.py migrate

# Run the web server.
uwsgi --http-auto-chunked --http-keepalive --static-map /static/=/opt/mailman-web-data/static/
