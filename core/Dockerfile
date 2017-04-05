FROM python:3.5

MAINTAINER Abhilash Raj

ENV DEBIAN_FRONTEND=noninteractive
# Install the latest master branch of the mailman directly
# from the Gitlab.
RUN apt-get update && apt-get install -y postgresql-client postfix \
    && pip install git+https://gitlab.com/mailman/mailman.git \
	               git+https://gitlab.com/mailman/mailman-hyperkitty.git \
	               psycopg2 ipython

ADD assets/run.sh /opt/run.sh

# Pidproxy is our sort-of process watcher that sends any
# signal that it receives to the mailman's master process.
ADD assets/pidproxy.py /opt/pidproxy.py

# Change the working directory.
WORKDIR /opt/mailman

EXPOSE 8001

CMD ["/opt/run.sh"]
