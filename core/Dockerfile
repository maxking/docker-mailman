FROM python:3.5

MAINTAINER Abhilash Raj

ENV DEBIAN_FRONTEND=noninteractive
# Install the latest master branch of the mailman directly
# from the Gitlab.
RUN apt-get update && apt-get install -y postgresql-client wget \
	&& wget -O mailman.zip https://gitlab.com/mailman/mailman/repository/archive.zip?ref=master  \
	&& wget -O mailman_hyperkitty.zip https://gitlab.com/mailman/mailman-hyperkitty/repository/archive.zip?ref=master  \
	&& pip install mailman.zip mailman_hyperkitty.zip ipython psycopg2 \
	&& rm mailman.zip mailman_hyperkitty.zip

ADD assets/run.sh /opt/run.sh

# Change the working directory.
WORKDIR /opt/mailman

EXPOSE 8001

ENTRYPOINT ["/opt/run.sh"]

CMD ["/usr/local/bin/master", "-C",  "/config/mailman.cfg"]
