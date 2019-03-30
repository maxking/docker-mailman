FROM alpine:3.8

MAINTAINER Abhilash Raj

#Add startup script to container
COPY docker-entrypoint.sh /usr/local/bin/

#Install all required packages, add user for executing mailman and set execution rights for startup script
RUN apk update \
	&& apk add --virtual build-deps gcc python3-dev musl-dev postgresql-dev \
	   libffi-dev \
	&& apk add --no-cache bash su-exec postgresql-client mysql-client curl python py3-setuptools \
	&& python3 -m pip install -U pip \
        && python3 -m pip install psycopg2 \
                   mailman==3.2.2 \
                   mailman-hyperkitty==1.1.0 \
                   pymysql \
    && apk del build-deps \
    && adduser -S mailman

# Change the working directory.
WORKDIR /opt/mailman

#Expose the ports for the api (8001) and lmtp (8024)
EXPOSE 8001 8024

ENV MAILMAN_CONFIG_FILE /etc/mailman.cfg

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["master", "--force"]
