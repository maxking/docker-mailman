#!/bin/bash
set -e

# If the DB environment variable is not set, use postgres.x
if [ "$DB" = "postgres" ] || [ -z $DB ]
then
	docker-compose -f docker-compose.yaml -f docker-test.yaml up -d
elif [ "$DB" = "mysql" ]
then
	docker-compose -f docker-compose-mysql.yaml -f docker-test.yaml up -d
fi

# Print the IP Addresses of the Containers.
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mailman-core
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mailman-web

# Make sure all the containers are running.
docker-compose ps

# Sleep for a while and check again if the containers are up.
sleep 60
docker ps

# Check if there is anything interesting in the logs.
docker logs mailman-web
docker logs mailman-core


# Check to see if the core is working as expected.
docker exec -it mailman-core curl -u restadmin:restpass http://172.19.199.2:8001/3.1/system | grep "GNU Mailman"

# Check to see if postorius is working.
docker exec -it mailman-web curl -L http://172.19.199.3:8000/postorius/lists | grep "Mailing List"

# Check to see if hyperkitty is working.
docker exec -it mailman-web  curl -L http://172.19.199.3:8000/hyperkitty/ | grep "Available lists"
