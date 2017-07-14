---
permalink: /
---

GNU Mailman 3 Deployment with Docker
====================================

This repository hosts code for two docker images `maxking/mailman-core` and
`maxking/mailman-web` both of which are meant to deploy [GNU Mailman 3][1] in
a production environment.

[Docker][2] is a container ecosystem which can run containers on several
platforms. It consists of a tool called [docker-compose][3] which can be used to
run multi-container applications. This repository consists of a
[`docker-compose.yaml`](docker-compose.yaml) file which is a set of
configurations that can be used to deploy the [Mailman 3 Suite][4].

Release
=======

The tags for the images are assumed to be release versions for images. This is
going to be somewhat common philosophy of distributing Container images where
the images with same tags are usually updated with the new functionality.

Releases will follow the following rules:

* Images tagged like A.B.C will never change. If you want to pin down versions
  of Images, use these tags.

* Images tagged with A.B will correspond to the latest A.B.C version
  released. Releases in A.B series are supposed to be backwards compatible
  i.e. any existing installation should not break when upgrading between
  subversions of A.B.C. So, if you want the latest updates and want to
  frequently update your installation without having to change the version
  numbers, you can use this.

* Any changes in the Mailman components of the Images will cause a bump in the
  Minor version i.e. A.(B+1) will have one (and only one) updated Mailman
  component from A.B. Also, significant change in functionality, that might
  change how Images work or how people interact with the containers, can also
  cause a bump in the minor version.

* Major versions will change either when there are backwards imcompatible
  changes or when the releases reach a certain set milestone.


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
recomended to use these instead of the one from your package managers. After you
have downloaded and installed docker, install docker-compose from [here][6].


Configuration
=============

Most of the configuraiton is supposed to be handled through environment
variables in the `docker-compose.yaml`.

### Mailman-web
These are the settings that you MUST change before deploying:

- `SERVE_FROM_DOMAIN`: The domain name from which Django will be served. To be
  added to `ALLOWED_HOSTS` in django settings. Default value is not set.

- `HYPERKITTY_API_KEY`: Hyperkitty's API Key, should be set to the same value as
  set for the mailman-core.

For more detauls on how to configure this image, please look at [Mailman-web's
Readme](web/README.md)

### Mailman-Core

These are the variables that you MUST change before deploying:

- `HYPERKITTY_API_KEY`: Hyperkitty's API Key, should be set to the same value as
  set for the mailman-core.

- `DATABASE_URL`: URL of the type
  `driver://user:password@hostname:port/databasename` for the django to use. If
  not set, the default is set to
  `sqlite:///opt/mailman-web-data/mailmanweb.db`. The standard
  docker-compose.yaml comes with it set to a postgres database. It is not must
  to change this if you are happy with postgresql.

- `DATABASE_TYPE`: It's value can be one of `sqlite`, `postgres` or `mysql` as
  these are the only three database types that Mailman 3 supports. It's defualt
  value is set to `sqlite` along with the default database class and default
  database url above.

- `DATABASE_CLASS`: Default value is
  `mailman.database.sqlite.SQLiteDatabase`. The values for this can be found in
  the mailman's documentation [here][11].

For more details on how to configure this image, please look [Mailman-core's
Readme](core/README.md)

If you need more advanced configuration, you can have configuration files for
Mailman Core and Django too. For Core, it needs to exist at
`/opt/mailman/core/mailman-extra.cfg`, anything in the configuration file will
override the default ones. For Django, you can add settings to
`/opt/mailman/web/settings_local.py` where you can override the default
settings.

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

This command will do several things, most importantly:

- Run a wsgi server using [`uwsgi`][7] for the Mailman's Django based web
  frontend listening on http://172.19.199.3:8000/. It will run 2 worker
  processes with 4 threads each. You may want to change the setting
  `ALLOWED_HOSTS` in the settings before deploying the application in
  production.

- Run a postgresql server with a default database, username and password as
  mentioned in the `docker-compose.yaml`. You will have to change configuration
  files too if you change any of these.

- Run mailman-core listening an LMTP server at http://172.19.199.2:8024/ for
  messages from MTA. You will have to configure your MTA to send messages at
  this address.

Some more details about what the above system achives is mentioned below. If you
are only going to deploy a simple configuration, you don't need to read
this. However, these are very easy to understand if you know how docker works.

- First create a bridge network called `mailman` in the
  `docker-compose.yaml`. It will probably be named something else in your
  machine, but it will use the `172.19.199.0/24` as subnet. All the containers
  mentioned (mailman-core, mailman-web, database) will join this network and are
  assigned static IPs. The host operating system is available at `172.19.199.1`
  from within these containers.

- Spin off mailman-core container which has a static IP address of
  `172.19.199.2` in the mailman bridge network created above. It has
  GNU Mailman 3 core running inside it. Mailman core's REST API is available at
  port 8001 and LMTP server listens at port 8024.

- Spin off mailman-web container which has a django application running with
  both Mailman's web frontend Portorius and Mailman's Web based Archiver
  running. [Uwsgi][7] server is used to run a web server with the configuration
  provided in this repository [here](web/assets/settings.py). You may want to
  change the setting `ALLOWED_HOSTS` in the settings before deploying the
  application in production. You can do that by adding a
  `/opt/mailman/web/settings_local.py` which is imported by the Django when
  running.

- Spin off a postgresql database container which is used by both mailman-core
  and mailman-web as their primary database.

- mailman-core mounts `/opt/mailman/core` from host OS at `/opt/mailman` in the
  container. Mailman's var directory is stored there so that it is accesible
  from the host operating system. Configuration for Mailman core is generated on
  every run from the environement variables provided. Extra configuration can
  also be provided at `/opt/mailman/core/mailman-extra.cfg` (on host), and will
  be added to generated configuration file. Mailman also needs another
  configuration file called
  [mailman-hyperkitty.cfg](core/assets/mailman-hyperkitty.cfg) and is also
  expected to be at `/opt/mailman/core/` on the host OS.

- mailman-web mounts `/opt/mailman/web` from the host OS to
  `/opt/mailman-web-data` in the container. It consists of the logs and
  settings_local.py file for Django.

- database mounts `/opt/mailman/database` at `/var/lib/postgresql/data` so that
  postgresql can persists its data even if the database containers are
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
  `/etc/exim4/conf.d/main/25_mm3_macros` in a typical debian instal of
  exim4. Please change MY_DOMAIN_NAME to the domain name that will be used to
  serve mailman. Multi-domains setups will be added later.

- [455_mm3_router](core/assets/exim/455_mm3_router) to be placed at
  `/etc/exim4/conf.d/main/455_mm3_router` in a typical debian instal of exim4.

- [55_mm3_transport](core/assets/exim/55_mm3_transport) to be placed at
  `/etc/exim4/conf.d/main/55_mm3_transport` in a typical debian instal of exim4.


Also, the default cofiguration inside the mailman-core image has MTA set to
Exim, but just for the reference, it looks like this:
```
# mailman.cfg
[mta]
incoming: mailman.mta.exim4.LMTP
outgoing: mailman.mta.deliver.deliver
lmtp_host: $MM_HOSTNAME                   # IP Address of mailman-core cotainer.
lmtp_port: 8024
smtp_host: $SMTP_HOST                     # IP Address of host where exim is.
smtp_port: $SMTP_PORT                     # Port on which exim is listening.
configuration: python:mailman.config.exim4
```


To use [Postfix][12], you can it should be setup to relay emails from
`172.19.199.2` and `172.19.199.3`. The mailman specific configuration is
mentioned below which you should add to you `main.cf` configuration file,
which is typically at `/etc/postfix/main.cf` on debian based operating
systems:

```
# master.cf

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
lmtp_host: 172.19.199.2                   # IP Address of mailman-core container
lmtp_port: 8024
smtp_host: 172.19.199.1                   # IP Address of host where postfix is.
smtp_port: 25
configuration: /etc/postfix-mailman.cfg
```

The configuration file `/etc/postfix-mailman.cfg` is generated automatically.

Setting up your web server
==========================

Although mailman-web runs uwsgi which can be used a full fledged web server, it
is recomended to run it behind a webserver like apache or nginx. I have included
setup instructions for nginx, but it is not difficult to find setup instructios
for Apache and Django.

Add the following to your nging's `/etc/nginx/site-available/default`

```
server {

        listen 443 ssl default_server;
        listen [::]:443 ssl default_server;

        server_name MY_SERVER_NAME;
        location /static/ {
             alias /opt/mailman/web/static/;
        }
        ssl_certificate /etc/letsencrypt/live/MY_DOMAIN_NAME/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/MY_DOMAIN_NAME/privkey.pem;

        location / {
                # First attempt to serve request as file, then
                include uwsgi_params;
                uwsgi_pass 172.19.199.3:8000;
                uwsgi_read_timeout 300;
        }

}

```

Please change MY_SERVER_NAME above to the domain name you will be serving the
Web UI from. It doesn't have to be same as the one used for Exim(or any MTA).

Also, change `ssl_certificate` and `ssl_certificate_key` options to point at
your SSL certificate and ceritfiicate keys. If you don't happen to have one, you
can get one for free from [Lets Encrypt][9]. They have a very nifty tool called
[certbot][10] that can be used to obtain the SSL certificates (typically stored
in the location mentioned above in the configuraiton if you replace
MY_DOMAIN_NAME with your domain name).

SSL Certificates from Lets Encrypt need to be renewed every 90 days. You can
setup a cron job to do the job. I have this small shell script(certbot-renew.sh)
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

This repository is licensed under MIT License. Please see the LICENSE file for
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
