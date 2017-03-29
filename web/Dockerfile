FROM python:2.7

MAINTAINER Abhilash Raj

RUN apt-get update \
	&& apt-get install -y ruby-sass \
					   git \
	&& python -m pip install git+https://gitlab.com/mailman/mailmanclient.git \
		   		   git+https://gitlab.com/mailman/postorius.git \
				   git+https://gitlab.com/mailman/django-mailman3.git \
				   git+https://gitlab.com/mailman/hyperkitty.git \
				   whoosh \
				   uwsgi


ADD mailman-web /opt/mailman-web

WORKDIR /opt/mailman-web

EXPOSE 8000

# ENV DJANGO_SETTINGS_MODULE=mailman-web.settings

ENV UWSGI_WSGI_FILE=wsgi.py UWSGI_HTTP=:8000 UWSGI_WORKERS=2 \
    UWSGI_THREADS=4

CMD  python manage.py collectstatic --noinput \
    && python manage.py migrate \
	&& uwsgi --http-auto-chunked --http-keepalive

#ADD assets/run.sh /opt/run.sh

#ENTRYPOINT /opt/run.sh

# CMD ["uwsgi", "--http-auto-chunked", "--http-keepalive"]
