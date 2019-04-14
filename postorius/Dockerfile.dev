FROM python:3.6-alpine3.6

MAINTAINER Abhilash Raj

# Add needed files for uwsgi server + settings for django
COPY mailman-web /opt/mailman-web
# Add startup script to container
COPY docker-entrypoint.sh /usr/local/bin/

ARG POSTORIUS_REF
ARG DJ_MM3_REF
ARG CLIENT_REF

# Install packages and dependencies for postorius and hyperkitty Add user for
# executing apps, change ownership for uwsgi+django files and set execution
# rights for management script
RUN set -ex \
	&& apk add --no-cache --virtual .build-deps gcc libc-dev linux-headers git \
	   	postgresql-dev mariadb-dev libffi-dev \
	&& apk add --no-cache --virtual .mailman-rundeps bash libffi \
	   postgresql-client mysql-client py-mysqldb curl mailcap \
	&& pip install -U git+https://gitlab.com/mailman/mailmanclient@${CLIENT_REF} \
		                git+https://gitlab.com/mailman/postorius@${POSTORIUS_REF} \
		                whoosh \
		                uwsgi \
		                psycopg2 \
		                dj-database-url \
		                mysqlclient \
	&& pip install -U 'Django<2.2' \
	&& pip install -U git+https://gitlab.com/mailman/django-mailman3@${DJ_MM3_REF} \
	&& apk del .build-deps \
	&& addgroup -S mailman \
	&& adduser -S -G mailman mailman \
	&& chown -R mailman /opt/mailman-web/ \
	&& chmod u+x /opt/mailman-web/manage.py

WORKDIR /opt/mailman-web

# Expose port 8000 for http and port 8080 for uwsgi
# (see web/mailman-web/uwsgi.ini#L2-L4)
EXPOSE 8000 8080

# Use stop signal for uwsgi server
STOPSIGNAL SIGINT

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["uwsgi", "--ini", "/opt/mailman-web/uwsgi.ini"]
