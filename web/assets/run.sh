#! /bin/bash
set -e

# Check if the database is available yet. Do not start the container before the
# postgresql boots up.
until psql $DATABASE_URL -c '\l'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - continuing"

# Check if the settings file is available and can be imported.


# Check if we are in the correct directory before running commands.
if [[ ! $(pwd) == '/opt/mailman-web' ]]; then
	echo "Running in the wrong directory...switching to /opt/mailman-web"
	cd /opt/mailman-web
fi


# Check if the settings file exists, exit it not.
if [[ ! -e /opt/mailman-web-data/settings.py ]]; then
	"Settings file does not exist, please provide one..."
	exit 1
fi

# Copy the settings file from /opt/mailman-web-data/ to the pwd because
# it is not on python-path.
cp /opt/mailman-web-data/settings.py /opt/mailman-web/settings.py

# Collect static for the django installation.
python manage.py collectstatic --noinput

# Migrate all the data to the database if this is a new installation, otherwise
# this command will upgrade the database.
python manage.py migrate

# Run the web server.
uwsgi --http-auto-chunked --http-keepalive --static-map /static/=/opt/mailman-web-data/static/
