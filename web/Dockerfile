FROM python:2.7-alpine3.6

MAINTAINER Abhilash Raj

# Add needed files for uwsgi server + settings for django
COPY mailman-web /opt/mailman-web
# Add startup script to container
COPY docker-entrypoint.sh /usr/local/bin/

# Install packages and dependencies for postorius and hyperkitty
# Add user for executing apps, change ownership for uwsgi+django files and set execution rights for management script
RUN set -ex \
	&& apk add --no-cache --virtual .build-deps gcc libc-dev linux-headers postgresql-dev mariadb-dev \
	&& apk add --no-cache --virtual .mailman-rundeps bash sassc postgresql-client \
	&& pip install -U mailmanclient==3.1.0 \
		postorius==1.1.0 \
		hyperkitty==1.1.1 \
		django-mailman3==1.1.0 \
		whoosh \
		uwsgi \
		psycopg2 \
		dj-database-url \
		mysqlclient>=1.3.3 \
		django==1.10 \
	&& apk del --no-cache .build-deps \
	&& addgroup -S mailman \
	&& adduser -S -G mailman mailman \
	&& chown -R mailman /opt/mailman-web/ \
	&& chmod u+x /opt/mailman-web/manage.py

WORKDIR /opt/mailman-web

# Expose port 8080 for uwsgi and port 8000 for http
EXPOSE 8000 8080

# Use stop signal for uwsgi server
STOPSIGNAL SIGINT

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["uwsgi", "--ini", "/opt/mailman-web/uwsgi.ini"]
