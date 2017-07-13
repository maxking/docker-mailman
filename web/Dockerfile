FROM python:2.7

MAINTAINER Abhilash Raj

ENV DEBIAN_FRONTEND=noninteractive
# Add needed files for uwsgi server + settings for django 
ADD mailman-web /opt/mailman-web
# Add startup script to container
ADD assets/run.sh /opt/run.sh

# Install packages and dependencies for postorius and hyperkitty
# Add user for executing apps, change ownership for uwsgi+django files and set execution rights for management script
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
	&& python -m pip install -U django==1.10 \
    && useradd -M -U -u 1000 mailman \
    && chmod u+x /opt/run.sh \
    && chown mailman /opt/mailman-web/* \
    && chmod u+x /opt/mailman-web/manage.py

WORKDIR /opt/mailman-web

# Expose port 8000 for uwsgi and port 8080 for http
EXPOSE 8000 8080

# Use stop signal for uwsgi server
STOPSIGNAL SIGINT

ENTRYPOINT ["/opt/run.sh"]
CMD ["uwsgi", "--ini", "/opt/mailman-web/uwsgi.ini"]