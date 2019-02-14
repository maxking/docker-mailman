---
permalink: /
---


GNU Mailman 3 Deployment with Docker
====================================

Table of Contents
-----------------

   * [GNU Mailman 3 Deployment with Docker](#gnu-mailman-3-deployment-with-docker)
   * [Release](#release)
   * [Rolling Releases](#rolling-releases)
      * [Security](#security)
   * [Dependencies](#dependencies)
   * [Configuration](#configuration)
      * [Mailman-web](#mailman-web)
      * [Mailman-Core](#mailman-core)
   * [Running](#running)
   * [Setting up your MTA](#setting-up-your-mta)
       * [uwsgi](#uwsgi)
   * [Setting up your web server](#setting-up-your-web-server)
       * [Serving static files](#serving-static-files)
       * [SSL certificates](#ssl-certificates)
   * [LICENSE](#license)


[![CircleCI](https://circleci.com/gh/maxking/docker-mailman/tree/master.svg?style=svg)](https://circleci.com/gh/maxking/docker-mailman/tree/master)

This repository hosts code for two docker images `maxking/mailman-core` and
`maxking/mailman-web` both of which are meant to deploy [GNU Mailman 3][1] in
a production environment.

[Docker][2] is a container ecosystem which can run containers on several
platforms. It consists of a tool called [docker-compose][3] which can be used to
run multi-container applications. This repository consists of a
[`docker-compose.yaml`](docker-compose.yaml) file which is a set of
configurations that can be used to deploy the [Mailman 3 Suite][4].

Please see [NEWS](NEWS.md) for the latest changes and releases.

Release
=======

The tags for the images are assumed to be release versions for images. This is
going to be a somewhat common philosophy of distributing Container images where
the images with same tags are usually updated with the new functionality.

Releases will follow the following rules:

* Images tagged like A.B.C will never change. If you want to pin down versions
  of Images, use these tags.

* Images tagged with A.B will correspond to the latest A.B.C version
  released. Releases in A.B series are supposed to be backwards compatible,
  i.e., any existing installation should not break when upgrading between
  subversions of A.B.C. So, if you want the latest updates and want to
  frequently update your installation without having to change the version
  numbers, you can use this.

* Any changes in the minor version of Mailman components of the images will
  cause a bump in the minor version, e.g., A.(B+1) will have one (and only one)
  updated Mailman component from A.B. Also, significant change in functionality,
  that might change how Images work or how people interact with the containers
  can also cause a bump in the minor version.

* Major versions will change either when there are backwards incompatible
  changes or when the releases reach a certain set milestone or when there are
  bugfix releases for the internal components or both.


Rolling Releases
================

Rolling releases are made up of Mailman Components installed from [git
source](https://gitlab.com/mailman). **Note that these releases are made up of
un-released software and should be assumed to be beta quality.**

Every commit is tested with Mailman's CI infrastructure and is included in
rolling releases only if they have passed the complete test suite.

```
$ docker pull quay.io/maxking/mailman-web:rolling
$ docker pull quay.io/maxking/mailman-core:rolling
```

Rolling releases are built with every commit and also re-generated weekly. You
can inspect the images to get which commit it was built using:

```bash
$ docker inspect --format '{{json .Config.Labels }}' mailman-core | python -m json.tool
{
    "version.core": "31f434d0",
    "version.git_commit": "45a4d7805b2b3d0e7c51679f59682d64ba02f05f",
    "version.mm3-hk": "c625bfd2"
}

$ docker inspect --format '{{json .Config.Labels }}' mailman-web | python -m json.tool
{
    "version.client": "d9e9cb73",
    "version.dj-mm3": "72a7d6c4",
    "version.git_commit": "45a4d7805b2b3d0e7c51679f59682d64ba02f05f",
    "version.hyperkitty": "b67ca8a8",
    "version.postorius": "73328ad4"
}

```

- `version.git_commit` : This is the commit hash of the Dockerfile in the
  [Github repo](https://github.com/maxking/docker-mailman)
- `version.core`: The commit hash of Mailman Core
- `version.mm3-hk`: The commit hash of Mailman3-hyperkitty plugin.
- `version.client`: The commit hash of Mailman Client.
- `version.hyperkitty`: The commit hash of Hyperkitty.
- `version.postorius`: The commit hash of Postorius.
- `version.dj-mm3`: The commit hash of Django-Mailman3 project.

Security
--------

All the releases are signed and can be verified using [Docker Content
Trust][14]. To make sure that your docker client actually verifies these
signatures, you can enable Docker's content trust by setting an environment
variable `DOCKER_CONTENT_TRUST`. In bash/zsh you can try this:

```bash
$ export DOCKER_CONTENT_TRUST=1
```

Or, alternatively, you can do this on a per-command basis without setting the
environment variable above. For example, when pulling an image:

```bash
$ docker pull --disable-content-trust=false maxking/mailman-core:release
```

The above command will fail if the release tag doesn't exist or is not signed.


Dependencies
============
- Docker
- Docker-compose

To run this you first need to download docker for whichever operating system you
are using. You can find documentation about [how to install][5]. It is
recommended to use these instead of the one from your package managers. After you
have downloaded and installed docker, install docker-compose from [here][6].


Configuration
=============

Most of the common configuration is handled through environment variables in the
`docker-compose.yaml`. However, there is need for some extra configuration that
interacts directly with the application. There are two configuration files on
the host that interact directly with Mailman's settings. These files exist on
the host running the containers and are imported at runtime in the containers.

* `/opt/mailman/core/mailman-extra.cfg` : This is the configuration for Mailman
  Core and anything that you add here will be added to Core's configuration. You
  need to restart your mailman-core container for the changes in this file to
  take effect.

* `/opt/mailman/web/settings_local.py` : This is the Django configuration that
  is imported by the [existing configuration](web/mailman-web/settings.py)
  provided by the mailman-web container. **This file is referred to as 
  `settings.py` in most of the Postorius and Django documentation.** To change
  or override any settings in Django/Postorius, you need to create/edit this file. 


Also, note that if you need any other files to be accessible from the host to
inside the container, you can place them at certain directories which are
mounted inside the containers.


* `/opt/mailman/core` in host maps to `/opt/mailman/` in mailman-core container.
* `/opt/mailman/web` in host maps to `/opt/mailman-web-data` in mailman-web
   container.

### Mailman-web
These are the settings that you MUST change before deploying:

- `SERVE_FROM_DOMAIN`: The domain name from which Django will be served. To be
  added to `ALLOWED_HOSTS` in django settings. Default value is not set. This
  also replaces Django's default `example.com` SITE and becomes the default SITE
  (with SITE_ID=1).

- `HYPERKITTY_API_KEY`: Hyperkitty's API Key, should be set to the same value as
  set for the mailman-core.

- `MAILMAN_ADMIN_USER`: The username for the admin user to be created by default.

- `MAILMAN_ADMIN_EMAIL`: The email for the admin user to be created by default.

- `SECRET_KEY`: Django's secret key, mainly used for signing cookies and others.

Please note here that if you choose to create the admin user using the environment
variables mentioned above (`MAILMAN_ADMIN_USER` & `MAILMAN_ADMIN_EMAIL`), no password
is set for your admin account. To set a password, plese follow the "Forgot Password"
link on the "Sign In" page.

To configure the mailman-web container to send emails, add this to your `settings_local.py`.:
```
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = '172.19.199.1'
EMAIL_PORT = 25
```
This is required in addition to the [Setup your MTA](#setting-up-your-mta) section below,
which covers email setup for Mailman Core.

For more details on how to configure this image, please look at [Mailman-web's
Readme](web/README.md)

### Mailman-Core

These are the variables that you MUST change before deploying:

- `HYPERKITTY_API_KEY`: Hyperkitty's API Key, should be set to the same value as
  set for the mailman-web.

- `DATABASE_URL`: URL of the type
  `driver://user:password@hostname:port/databasename` for the django to use. If
  not set, the default is set to
  `sqlite:///opt/mailman-web-data/mailmanweb.db`. The standard
  docker-compose.yaml comes with it set to a postgres database. There is no need
  to change this if you are happy with PostgreSQL.

- `DATABASE_TYPE`: Its value can be one of `sqlite`, `postgres` or `mysql` as
  these are the only three database types that Mailman 3 supports. Its default
  value is set to `sqlite` along with the default database class and default
  database url above.

- `DATABASE_CLASS`: Default value is
  `mailman.database.sqlite.SQLiteDatabase`. The values for this can be found in
  the mailman's documentation [here][11].

For more details on how to configure this image, please look [Mailman-core's
Readme](core/README.md)


While the above configuration will allow you to run the images and possibly view
the Web Frontend, it won't be functional until it is fully configured to to send
emails.

To configure the mailman-core container to send emails, see the [Setting your MTA
section below](#setting-up-your-mta).

Running
=======

To run the containers, simply run:

```bash
$ mkdir -p /opt/mailman/core
$ mkdir -p /opt/mailman/web
$ git clone https://github.com/maxking/docker-mailman
$ cd docker-mailman
# Change some configuration variables as mentioned above.
$ docker-compose up -d
```

Note that the web frontend in the mailman-web container is, by default, only
configured to serve dynamic content. Anything static like stylesheets, etc., is
expected to be served directly by the web server. The static content exists at
`/opt/mailman/web/static` and should be _aliased_ to `/static/` in the web
server configuration.

See [the nginx configuration][17] as an example.




This command will do several things, most importantly:

- Run a wsgi server using [`uwsgi`][7] for the Mailman's Django-based web
  frontend listening on http://172.19.199.3:8000/. It will run 2 worker
  processes with 4 threads each. You may want to change the setting
  `ALLOWED_HOSTS` in the settings before deploying the application in
  production.

- Run a PostgreSQL server with a default database, username, and password as
  mentioned in the `docker-compose.yaml`. You will have to change configuration
  files too if you change any of these.

- Run mailman-core listening an LMTP server at http://172.19.199.2:8024/ for
  messages from your MTA. You will have to configure your MTA to send messages at
  this address.

Some more details about what the above system achieves is mentioned below. If you
are only going to deploy a simple configuration, you don't need to read
this. However, these are very easy to understand if you know how docker works.

- First create a bridge network called `mailman` in the
  `docker-compose.yaml`. It will probably be named something else in your
  machine, but it will use the `172.19.199.0/24` as subnet. All the containers
  mentioned (mailman-core, mailman-web, database) will join this network and are
  assigned static IPs. The host operating system is available at `172.19.199.1`
  from within these containers.

- Spin off a mailman-core container which has a static IP address of
  `172.19.199.2` in the mailman bridge network created above. It has
  GNU Mailman 3 core running inside it. Mailman core's REST API is available at
  port 8001 and LMTP server listens at port 8024.

- Spin off a mailman-web container which has a Django application running with
  both Mailman's web frontend Postorius and Mailman's web-based Archiver
  running. [Uwsgi][7] server is used to run a web server with the configuration
  provided in this repository [here](web/assets/settings.py). You may want to
  change the setting `ALLOWED_HOSTS` in the settings before deploying the
  application in production. You can do that by adding a
  `/opt/mailman/web/settings_local.py` which is imported by the Django when
  running.

- Spin off a PostgreSQL database container which is used by both mailman-core
  and mailman-web as their primary database.

- mailman-core mounts `/opt/mailman/core` from host OS at `/opt/mailman` in the
  container. Mailman's var directory is stored there so that it is accessible
  from the host operating system. Configuration for Mailman core is generated on
  every run from the environment variables provided. Extra configuration can
  also be provided at `/opt/mailman/core/mailman-extra.cfg` (on host), and will
  be added to generated configuration file. Mailman also needs another
  configuration file called
  [mailman-hyperkitty.cfg](core/assets/mailman-hyperkitty.cfg) and is also
  expected to be at `/opt/mailman/core/` on the host OS.

- mailman-web mounts `/opt/mailman/web` from the host OS to
  `/opt/mailman-web-data` in the container. It consists of the logs and
  settings_local.py file for Django.

- database mounts `/opt/mailman/database` at `/var/lib/postgresql/data` so that
  PostgreSQL can persist its data even if the database containers are
  updated/changed/removed.

Setting up your MTA
===================

The provided docker containers do not have an MTA in-built. You can either run
your own MTA inside a container and have them relay emails to the mailman-core
container or just install an MTA on the host and have them relay emails.

To use [Exim4][8], it should be setup to relay emails from `172.19.199.3` and
`172.19.199.2`. The mailman specific configuration is provided in the repository
at `core/assets/exim`. There are three files

- [25_mm_macros](core/assets/exim/25_mm3_macros) to be placed at
  `/etc/exim4/conf.d/main/25_mm3_macros` in a typical Debian install of
  exim4. Please change MY_DOMAIN_NAME to the domain name that will be used to
  serve mailman. Multi-domain setups will be added later.

- [455_mm3_router](core/assets/exim/455_mm3_router) to be placed at
  `/etc/exim4/conf.d/router/455_mm3_router` in a typical Debian install of exim4.

- [55_mm3_transport](core/assets/exim/55_mm3_transport) to be placed at
  `/etc/exim4/conf.d/transport/55_mm3_transport` in a typical Debian install of exim4.


Also, the default configuration inside the mailman-core image has the MTA set to
Exim, but just for reference, it looks like this:
```
# mailman.cfg
[mta]
incoming: mailman.mta.exim4.LMTP
outgoing: mailman.mta.deliver.deliver
lmtp_host: $MM_HOSTNAME
lmtp_port: 8024
smtp_host: $SMTP_HOST
smtp_port: $SMTP_PORT
configuration: python:mailman.config.exim4
```


To use [Postfix][12], edit the `main.cf` configuration file,
which is typically at `/etc/postfix/main.cf` on Debian-based operating
systems.  Add `172.19.199.2` and `172.19.199.3` to `mynetworks` so it will relay emails from the containers and add the following configuration lines:

```
# main.cf

# Support the default VERP delimiter.
recipient_delimiter = +
unknown_local_recipient_reject_code = 550
owner_request_special = no

transport_maps =
    regexp:/opt/mailman/core/var/data/postfix_lmtp
local_recipient_maps =
    regexp:/opt/mailman/core/var/data/postfix_lmtp
relay_domains =
    regexp:/opt/mailman/core/var/data/postfix_domains
```

To configure Mailman to use Postfix, add the following to `mailman-extra.cfg` at
`/opt/mailman/core/mailman-extra.cfg`.

```
# mailman-extra.cfg

[mta]
incoming: mailman.mta.postfix.LMTP
outgoing: mailman.mta.deliver.deliver
lmtp_host: 172.19.199.2
lmtp_port: 8024
smtp_host: 172.19.199.1
smtp_port: 25
configuration: /etc/postfix-mailman.cfg
```

The configuration file `/etc/postfix-mailman.cfg` is generated automatically.

Setting up your web server
==========================

It is advisable to run your Django (interfaced through WSGI server) through an
_actual_ webserver in production for better performance.

If you are using v0.1.0, the uwsgi server is configured to listen to requests at
`172.19.199.3:8000` using the `HTTP` protocol. Make sure that you preserve the `HOST`
header when you proxy the requests from your Web Server. In Nginx you can do
that by adding the following to your configuration:

```
       # Nginx configuration.

        location / {
		 # First attempt to serve request as file, then

		  proxy_pass http://172.19.199.3:8000;
		  include uwsgi_params;
		  uwsgi_read_timeout 300;
		  proxy_set_header Host $host;
		  proxy_set_header X-Forwarded-For $remote_addr;
        }

```

Make sure you are using `proxy_pass` for the `HTTP` protocol.

uwsgi
-----

Starting from v0.1.1, the uwsgi server is configured to listen to requests at
`172.19.199.3:8000` with the http protocol and `172.19.199.3:8080` for the uwsgi
protocol.

**Please make sure that you are using port 8080 for uwsgi protocol.**

It is advised to use the uwsgi protocol as it has better performance. Both
Apache and Nginx have native support for the uwsgi protocol through plugins which
are generally included in the distro packages.

To move to uwsgi protocol in the above nginx configuration use this

```
       # Nginx configuration.

        location / {
		 # First attempt to serve request as file, then

		  uwsgi_pass 172.19.199.3:8080;
		  include uwsgi_params;
		  uwsgi_read_timeout 300;
        }
```

Please make sure that you are using v0.1.1 or greater if you use this configuration.


### Serving static files

UWSGI by default doesn't serve static files so, when running
`mailman-web` using the provided `docker-compose.yaml` file, you won't see any
CSS or JS files being served.

To enable serving of static files using UWSGI, add the following environment
variable to your `docker-compose.yaml` file under `mailman-web`:

```
UWSGI_STATIC_MAP=/static=/opt/mailman-web-data/static
```

It is recommended to use web-server to serve static files instead of UWSGI for
better performance. You will have to add an alias rule in your web server to
serve the static files. See [here][18] for instructions on how to configure your
web server. The STATIC_ROOT for you would be `/opt/mailman/web/static`.

### SSL certificates

SSL Certificates from Lets Encrypt need to be renewed every 90 days. You can
setup a cron job to do the job. I have this small shell script (certbot-renew.sh)
that you can put up in `/etc/cron.monthly` to get the job done.

```
#! /bin/bash

cd /opt/letsencrypt/
./certbot-auto --config /etc/letsencrypt/renewal/MY_DOMAIN_NAME.conf certonly

if [ $? -ne 0 ]
 then
        ERRORLOG=`tail /var/log/letsencrypt/letsencrypt.log`
        echo -e "The Let's Encrypt cert has not been renewed! \n \n" \
                 $ERRORLOG
 else
        nginx -s reload
fi

exit 0
```

Please do not forget to make the script executable (chmod +x certbot-renew.sh).

LICENSE
=======

This repository is licensed under the MIT License. Please see the LICENSE file for
more details.

[1]: http://list.org
[2]: https://www.docker.com/
[3]: https://docs.docker.com/compose/
[4]: http://docs.mailman3.org/en/latest/
[5]: https://docs.docker.com/engine/installation/
[6]: https://docs.docker.com/compose/install/
[7]: https://uwsgi-docs.readthedocs.io/en/latest/
[8]: http://exim.org/
[9]: https://letsencrypt.org/
[10]: https://certbot.eff.org/
[11]: https://mailman.readthedocs.io/en/latest/src/mailman/docs/database.html
[12]: http://www.postfix.org/
[13]: http://semver.org/
[14]: https://docs.docker.com/engine/security/trust/content_trust/
[15]: http://docs.mailman3.org/en/latest/config-web.html#setting-up-email
[17]: http://docs.mailman3.org/en/latest/prodsetup.html#nginx-configuration
[18]: http://docs.list.org/en/latest/pre-installation-guide.html#django-static-files
