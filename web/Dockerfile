# syntax = docker/dockerfile:1.3
FROM alpine:3.21.0

# Add requirements file.
COPY requirements.txt /tmp/

# Install packages and dependencies for postorius and hyperkitty Add user for
# executing apps, change ownership for uwsgi+django files and set execution
# rights for management script
RUN --mount=type=cache,target=/root/.cache \
    set -ex \
	&& apk add --no-cache --virtual .build-deps gcc libc-dev linux-headers \
           postgresql-dev mariadb-dev mariadb-connector-c python3-dev libffi-dev openldap-dev cargo rust \
	&& apk add --no-cache --virtual .mailman-rundeps bash sassc tzdata libldap \
	   postgresql-client mysql-client py3-mysqlclient curl mailcap gettext \
	   python3 py3-pip xapian-core xapian-bindings-python3 libffi pcre-dev py-cryptography \
	&& python3 -m pip install --break-system-packages -U 'Django<4.3' pip setuptools wheel \
	&& pip install --break-system-packages -r /tmp/requirements.txt \
		whoosh \
		uwsgi \
		psycopg2 \
		dj-database-url \
		mysqlclient \
		typing \
		xapian-haystack \
		django-auth-ldap \
		pymemcache \
		diskcache \
		django-utils-six \
		tzdata \
		pytz \
		'django-allauth[socialaccount,openid]' \
	&& apk del .build-deps \
	&& addgroup -S mailman \
	&& adduser -S -G mailman mailman

# Add needed files for uwsgi server + settings for django
COPY mailman-web /opt/mailman-web
# Add startup script to container
COPY docker-entrypoint.sh /usr/local/bin/

RUN chown -R mailman /opt/mailman-web/ \
	&& chmod u+x /opt/mailman-web/manage.py

WORKDIR /opt/mailman-web

# Expose port 8000 for http and port 8080 for uwsgi
# (see web/mailman-web/uwsgi.ini#L2-L4)
EXPOSE 8000 8080

# Use stop signal for uwsgi server
STOPSIGNAL SIGINT

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["uwsgi", "--ini", "/opt/mailman-web/uwsgi.ini"]
