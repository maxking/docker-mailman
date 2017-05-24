FROM python:3.6-alpine

MAINTAINER Abhilash Raj

# Install the latest master branch of the mailman directly
# from the Gitlab.
RUN apk update \
    && apk add --virtual build-deps gcc python3-dev musl-dev wget \
    && apk add postgresql-dev bash su-exec \
    && wget -O mailman_hyperkitty.zip https://gitlab.com/mailman/mailman-hyperkitty/repository/archive.zip?ref=master  \
    && pip install mailman_hyperkitty.zip psycopg2 mailman==3.1.0rc1 \
    && rm mailman_hyperkitty.zip \
    && apk del build-deps

ADD assets/run.sh /opt/run.sh

# Change the working directory.
WORKDIR /opt/mailman

EXPOSE 8001

ENTRYPOINT ["/opt/run.sh"]

ENV MAILMAN_CONFIG_FILE /config/mailman.cfg

RUN adduser -S mailman

CMD ["/usr/local/bin/master"]
