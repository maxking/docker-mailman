# syntax = docker/dockerfile:1.3
# Use 3.15 for Core since it has Python 3.9
FROM alpine:3.22

# Add requirements file.
COPY requirements.txt /tmp/

#Install all required packages, add user for executing mailman and set execution rights for startup script
RUN --mount=type=cache,target=/root/.cache \
    apk update \
    && apk add --virtual build-deps gcc python3-dev musl-dev postgresql-dev \
       libffi-dev \
  # Mailman html to plaintext conversion uses lynx.
  # psutil needs linux-headers to compile on musl c library.
    && apk add --no-cache bash su-exec postgresql-client mysql-client curl python3 py3-pip linux-headers py-cryptography mariadb-connector-c lynx tzdata \
    && python3 -m pip install --break-system-packages -U pip setuptools wheel \
        && python3 -m pip install --break-system-packages psycopg2 \
                   pymysql \
                   -r /tmp/requirements.txt \
                   'importlib-resources<6.0.0' \
    && apk del build-deps \
    && adduser -S mailman

#Add startup script to container
COPY docker-entrypoint.sh /usr/local/bin/

# Change the working directory.
WORKDIR /opt/mailman

#Expose the ports for the api (8001) and lmtp (8024)
EXPOSE 8001 8024

ENV MAILMAN_CONFIG_FILE /etc/mailman.cfg

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["master", "--force"]
