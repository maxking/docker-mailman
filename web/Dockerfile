FROM python:2.7

MAINTAINER Abhilash Raj

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install -y --no-install-recommends ruby-sass \
					   wget \
					   postgresql-client \
	&& rm -rf /var/lib/apt/lists/*

RUN wget -O mailmanclient.zip https://gitlab.com/mailman/mailmanclient/repository/archive.zip?ref=master \
	&& wget -O postorius.zip https://gitlab.com/mailman/postorius/repository/archive.zip?ref=master \
	&& wget -O django-mailman3.zip https://gitlab.com/mailman/django-mailman3/repository/archive.zip?ref=master \
	&& wget -O hyperkitty.zip https://gitlab.com/mailman/hyperkitty/repository/archive.zip?ref=master \
    && python -m pip install -U mailmanclient.zip \
	                         	postorius.zip \
							 	django-mailman3.zip \
							 	hyperkitty.zip \
		  				     	whoosh \
				             	uwsgi \
				             	psycopg2 \
				             	dj-database-url \
							 	pymysql \
	&& rm mailmanclient.zip postorius.zip hyperkitty.zip django-mailman3.zip

ADD mailman-web /opt/mailman-web

ADD assets/run.sh /opt/run.sh

WORKDIR /opt/mailman-web

EXPOSE 8000

ENTRYPOINT ["/opt/run.sh"]

CMD ["uwsgi", "--http-auto-chunked --http-keepalive --logto $UWSGI_LOG_URL"]
