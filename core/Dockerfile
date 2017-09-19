FROM python:3.6-alpine

MAINTAINER Abhilash Raj

#Add startup script to container
COPY docker-entrypoint.sh /usr/local/bin/

#Install all required packages, add user for executing mailman and set execution rights for startup script
RUN apk update \
    && apk add --virtual build-deps gcc python3-dev musl-dev mysql-dev postgresql-dev \
    && apk add mariadb-client bash su-exec postgresql-client mariadb-client mariadb-client-libs \
    && pip install psycopg2 mailman==3.1.0 mailman-hyperkitty==1.1.0 mysqlclient \
    && apk del build-deps \
    && adduser -S mailman

# Change the working directory.
WORKDIR /opt/mailman

#Expose the ports for the api (8001) and lmtp (8024)
EXPOSE 8001 8024

ENV MAILMAN_CONFIG_FILE /etc/mailman.cfg

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["master"]
