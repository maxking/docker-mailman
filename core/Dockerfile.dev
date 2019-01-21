FROM alpine:3.8

MAINTAINER Abhilash Raj

#Add startup script to container
COPY docker-entrypoint.sh /usr/local/bin/

# Set the commits that we are building.
ARG CORE_REF
ARG MM3_HK_REF


#Install all required packages, add user for executing mailman and set execution
#rights for startup script
RUN apk update \
	&& apk add --no-cache --virtual build-deps gcc python3-dev musl-dev \
   	    postgresql-dev git libffi-dev  \
    && apk add --no-cache bash su-exec postgresql-client mysql-client curl python3 py3-setuptools \
    && python3 -m pip install -U psycopg2 pymysql \
        git+https://gitlab.com/mailman/mailman@${CORE_REF} \
        git+https://gitlab.com/mailman/mailman-hyperkitty@${MM3_HK_REF} \
    && apk del build-deps \
    && adduser -S mailman

# Change the working directory.
WORKDIR /opt/mailman

#Expose the ports for the api (8001) and lmtp (8024)
EXPOSE 8001 8024

# Set the default configuration file.
ENV MAILMAN_CONFIG_FILE /etc/mailman.cfg

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["master"]
