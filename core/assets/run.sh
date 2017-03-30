#! /bin/bash
set -e

# Check if the configuration file is present.
if [[ ! -e /opt/mailman/mailman.cfg ]]; then
	echo "/opt/mailman/mailman.cfg configuration file not found..."
	exit 1
fi

if [[ ! -e /opt/mailman/mailman-hyperkitty.cfg ]]; then
	echo "/opt/mailman/mailman-hyperkitty.cfg configuration file not found..."
	echo "Hyperkitty will not be enabled or will not work properly..."
fi

# Check if the master lock exists for the mailman.
# It means that that either some other mailman process is running or
# the last time mailman did not exit clean.
if [[ -e /opt/mailman/core/var/locks/master.lck ]]; then
	echo "The mailman's master lock file still exists at /opt/mailman/core/var/locks/master.lck"
	echo "Please remove the lock file before trying to run this container again."
	exit 1
fi

# Check if the database is available yet. Do not start the container before the
# postgresql boots up.
until psql $DATABASE_URL -c '\l'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - continuing"


# Run mailman using the pidproxy command which spawns off mailman
# and forwards any signal you send it to the master runner in mailman.
/opt/pidproxy.py /opt/mailman/var/master.pid mailman -C /opt/mailman/mailman.cfg start --force
