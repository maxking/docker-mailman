FROM python:3.6-alpine

MAINTAINER Abhilash Raj

# Install the latest master branch of the mailman directly
# from the Gitlab.
RUN apk update \
    && apk add --virtual build-deps gcc python3-dev musl-dev \
    && apk add postgresql-dev bash su-exec postgresql-client \
    && pip install psycopg2 mailman==3.1.0 mailman-hyperkitty==1.1.0 \
    && apk del build-deps

ADD assets/run.sh /opt/run.sh

# Change the working directory.
WORKDIR /opt/mailman

EXPOSE 8001

ENTRYPOINT ["/opt/run.sh"]

ENV MAILMAN_CONFIG_FILE /etc/mailman.cfg

RUN adduser -S mailman

CMD ["/usr/local/bin/master"]
