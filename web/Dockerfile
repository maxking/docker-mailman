FROM python:2.7

MAINTAINER Abhilash Raj

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends ruby-sass \
                       wget \
                       postgresql-client \
    && rm -rf /var/lib/apt/lists/* \
    && python -m pip install -U mailmanclient==3.1.0 \
                             postorius==1.1.0 \
                             hyperkitty==1.1.0 \
                             django-mailman3==1.1.0 \
                             whoosh \
                             uwsgi \
                             psycopg2 \
                             dj-database-url \
                             pymysql \
	&& python -m pip install -U django==1.10

ENV GOSU_VERSION 1.10
RUN set -ex; \
	\
	fetchDeps=' \
		ca-certificates \
		wget \
	'; \
	apt-get update; \
	apt-get install -y --no-install-recommends $fetchDeps; \
	rm -rf /var/lib/apt/lists/*; \
	\
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	\
# verify the signature
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	\
	chmod +x /usr/local/bin/gosu; \
# verify that the binary works
	gosu nobody true; \
	\
	apt-get purge -y --auto-remove $fetchDeps

ADD mailman-web /opt/mailman-web

RUN useradd -M -U -u 1000 mailman

ADD assets/run.sh /opt/run.sh

WORKDIR /opt/mailman-web

EXPOSE 8000

ENTRYPOINT ["/opt/run.sh"]

CMD ["uwsgi", "--ini", "/opt/mailman-web/uwsgi.ini"]
