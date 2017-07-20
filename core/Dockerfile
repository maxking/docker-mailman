FROM python:3.6-alpine

MAINTAINER Abhilash Raj

#Add startup script to container
ADD assets/run.sh /opt/run.sh

#Install all required packages, add user for executing mailman and set execution rights for startup script
RUN apk update \
    && apk add --virtual build-deps gcc python3-dev musl-dev \
    && apk add postgresql-dev bash su-exec postgresql-client \
    && pip install psycopg2 mailman==3.1.0 mailman-hyperkitty==1.1.0 \
	&& pip install pymysql
    && apk del build-deps \
    && adduser -S mailman \
    && chmod a+x /opt/run.sh

# Change the working directory.
WORKDIR /opt/mailman

#Expose the ports for the api (8001) and lmtp (8024)
EXPOSE 8001 8024

ENV MAILMAN_CONFIG_FILE /etc/mailman.cfg

ENTRYPOINT ["/opt/run.sh"]
CMD ["/usr/local/bin/master"]
