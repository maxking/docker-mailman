FROM alpine:3.8

MAINTAINER Abhilash Raj

# Add needed files for uwsgi server + settings for django
COPY mailman-web /opt/mailman-web
# Add startup script to container
COPY docker-entrypoint.sh /usr/local/bin/

ARG POSTORIUS_REF
ARG HYPERKITTY_REF
ARG DJ_MM3_REF
ARG CLIENT_REF

# Install packages and dependencies for postorius and hyperkitty Add user for
# executing apps, change ownership for uwsgi+django files and set execution
# rights for management script
RUN set -ex \
    && apk add --no-cache --virtual .build-deps gcc libc-dev linux-headers git \
        postgresql-dev mariadb-dev python3-dev libffi-dev \
    && apk add --no-cache --virtual .mailman-rundeps bash sassc \
      python3 py3-setuptools postgresql-client mysql-client py-mysqldb\
        curl mailcap xapian-core xapian-bindings-python3 libffi \
    && python3 -m pip install -U \
        git+https://gitlab.com/mailman/mailmanclient@${CLIENT_REF} \
        git+https://gitlab.com/mailman/postorius@${POSTORIUS_REF} \
        git+https://gitlab.com/mailman/hyperkitty@${HYPERKITTY_REF} \
        whoosh \
        uwsgi \
        psycopg2 \
        dj-database-url \
        mysqlclient \
        xapian-haystack \
    && python3 -m pip install -U 'Django<2.2' \
    && python3 -m pip install -U \
       git+https://gitlab.com/mailman/django-mailman3@${DJ_MM3_REF} \
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
