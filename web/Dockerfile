FROM python:2.7

MAINTAINER Abhilash Raj

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends ruby-sass \
                       wget \
                       postgresql-client \
    && rm -rf /var/lib/apt/lists/*

RUN python -m pip install -U mailmanclient==3.1.0 \
                             postorius==1.1.0 \
                             hyperkitty==1.1.0 \
                             django-mailman3==1.1.0 \
                             whoosh \
                             uwsgi \
                             psycopg2 \
                             dj-database-url \
                             pymysql \
	&& python -m pip install -U django==1.10

ADD mailman-web /opt/mailman-web

ADD assets/run.sh /opt/run.sh

WORKDIR /opt/mailman-web

EXPOSE 8000

ENTRYPOINT ["/opt/run.sh"]

CMD ["uwsgi", "--ini", "/opt/mailman-web/uwsgi.ini"]
