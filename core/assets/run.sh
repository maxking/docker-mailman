#! /bin/bash

# Check if the configuration file is present.
if [[ ! -e /opt/mailman/mailman.cfg ]]; then
	echo "/opt/mailman/mailman.cfg configuration file not found..."
	exit 1
fi

# Run mailman using the pidproxy command which spawns off mailman
# and forwards any signal you send it to the master runner in mailman.
/opt/pidproxy.py /opt/mailman/var/master.pid mailman -C /opt/mailman/mailman.cfg start --force
