#!/bin/sh

POD_NAME=mailman;
DOMAIN=localhost.localdomain;

echo -e "
$0 will generate a pod named ${POD_NAME}
A pod is a unit of encapsulation that includes
\t* 1 network
\t* 3 containers with 1 volume each


For more information see
  podman pod inspect ${POD_NAME}
"

# 8080 is uwsgi, 8080 is http
podman pod create \
	--publish 8080:8080 \
	--publish 8000:8000 \
	"$POD_NAME";

podman run \
	--pod="$POD_NAME" \
	--name="${POD_NAME}-db" \
	--detach \
	--volume mailman-db:/var/lib/postgresql/data \
	-e=POSTGRES_DB=mailmandb \
	-e=POSTGRES_USER=mailman \
	-e=POSTGRES_PASSWORD=mailmanpass \
	postgres:15-alpine;

podman run \
	--detach \
	-ti \
	--pod="$POD_NAME" \
	--name="${POD_NAME}-core" \
	--volume mailman-core:/opt/mailman \
	--requires="${POD_NAME}-db" \
	--env="DATABASE_CLASS=mailman.database.postgresql.PostgreSQLDatabase" \
	--env="DATABASE_TYPE=postgres" \
	--env="DATABASE_URL=postgresql://mailman:mailmanpass@${POD_NAME}/mailmandb" \
	--env="HYPERKITTY_API_KEY=someapikey" \
	--env="HYPERKITTY_URL=http://localhost:8000/hyperkitty" \
	--env="MAILMAN_REST_URL=http://${POD_NAME}:8001" \
	--expose 8001 \
	maxking/mailman-core:rolling;


podman run \
	--detach \
	--pod="$POD_NAME" \
	--name="${POD_NAME}-web" \
	--requires="${POD_NAME}-db,${POD_NAME}-core" \
	--volume mailman-web:/opt/mailman/web \
	--env="DATABASE_TYPE=postgres" \
	--env="DATABASE_URL=postgresql://mailman:mailmanpass@${POD_NAME}/mailmandb" \
	--env="HYPERKITTY_API_KEY=someapikey" \
	--env="HYPERKITTY_URL=http://localhost:8000/hyperkitty" \
	--env="MAILMAN_HOSTNAME=$DOMAIN" \
	--env="MAILMAN_REST_URL=http://${POD_NAME}:8001" \
	--env="SECRET_KEY=thisisaverysecretkey" \
	--env="SERVE_FROM_DOMAIN=$DOMAIN" \
	--env="UWSGI_STATIC_MAP=/static=/opt/mailman-web-data/static" \
	maxking/mailman-web:rolling;
