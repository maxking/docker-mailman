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


Dependencies
============
- Docker
- Docker-compose

To run this you first need to download docker for whichever operating system you
are using. You can find documentation about [how to install][5]. It is
recomended to use these instead of the one from your package managers. After you
have downloaded and installed docker, install docker-compose from [here][6].

Running
=======

To run the containers, simply run:

```bash
$ docker-compose up
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
  port 8000 and LMTP server listens at port 8024.

- Spin off mailman-web container which has a django application running with
  both Mailman's web frontend Portorius and Mailman's Web based Archiver
  running. [Uwsgi][7] server is used to run a web server with the configuration
  provided in this repository [here](web/assets/settings.py). You may want to
  change the setting `ALLOWED_HOSTS` in the settings before deploying the
  application in production.

- Spin off a postgresql database container which is used by both mailman-core
  and mailman-web as their primary database.

- mailman-core mounts `/opt/mailman/core` from host OS at `/opt/mailman` in the
  container. Mailman's var directory is stored there so that it is accesible
  from the host operating system. Mailman's configuration file is also expected
  to be present there. A [production level
  configuration](core/assets/mailman.cfg) is provided, but please do not change
  anything there without the complete knowledge. Mailman also needs another
  configuration file called
  [mailman-hyperkitty.cfg](core/assets/mailman-hyperkitty.cfg) and is also
  expected to be at `/opt/mailman/core/` on the host OS.

- mailman-web mounts `/opt/mailman/web` from the host OS to
  `/opt/mailman-web-data` in the container. It consists of the logs and
  settings.py file for Django.

- database mounts `/opt/mailman/database` at `/var/lib/postgresql/data` so that
  postgresql can persists its data even if the database containers are
  updated/changed/removed.

Setting up your MTA
===================

This setup assumes that the MTA is actually present on the host. In future it is
possible to provide a way to actually expect nothing from the host and have
everything running inside containers.

It is recomended to use [Exim4][8] along with this setup. Technically, it
possible to use any other MTA like postfix too, but I haven't yet been able to
figure out a clean way to communicate with postfix on the host.

Exim should be setup to relay emails from `172.19.199.3` and `172.19.199.2`. The
mailman specific configuration is provided in the repository at
`core/assets/exim`. There are three files

- [25_mm_macros](core/assets/exim/25_mm3_macros) to be placed at
  `/etc/exim4/conf.d/main/25_mm3_macros` in a typical debian instal of
  exim4. Please change MY_DOMAIN_NAME to the domain name that will be used to
  serve mailman. Multi-domains setups will be added later.

- [455_mm3_router](core/assets/exim/455_mm3_router) to be placed at
  `/etc/exim4/conf.d/main/455_mm3_router` in a typical debian instal of exim4.

- [55_mm3_transport](core/assets/exim/55_mm3_transport) to be placed at
  `/etc/exim4/conf.d/main/55_mm3_transport` in a typical debian instal of exim4.


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
        proxy_set_header X-Real-IP  $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header Host $host;
        proxy_pass http://172.19.199.3:8000;

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

Configuration
=============

Most of the configuraiton is supposed to be handled through environment
variables in the `docker-compose.yaml`.

### Mailman-web
These are the settings that you MUST change before deploying:

- `SERVE_FROM_DOMAIN`: The domain name from which Django will be served. To be
  added to `ALLOWED_HOSTS` in django settings. Default value is not set.

- `HYPERKITT_API_KEY`: Hyperkitty's API Key, should be set to the same value as
  set for the mailman-core.

These are the settings that are set to sane default and you do not need to
change them unless you know what you want.

- `DATABASE_URL`: URL of the type
  `driver://user:password@hostname:port/databasename` for the django to use. If
  not set, the default is set to
  `sqlite:///opt/mailman-web-data/mailmanweb.db`. The standard
  docker-compose.yaml comes with it set to a postgres database. It is not must
  to change this if you are happy with postgresql.

- `MAILMAN_REST_URL`: The URL to the Mailman core's REST API server.  Defaut
  value is `http://mailman-core:8001`.

- `MAILMAN_REST_USER`: Mailman's REST API username. Default value is `restadmin`

- `MAILMAN_REST_PASSWORD`: Mailman's REST API user's password. Default value is
  `restpass`

- `DJANGO_HOST_IP`: IP of the container from which the django will be
  served. Default value is `172.19.199.3`.

- `SMTP_HOST`: IP Address/hostname from which you will be sending
  emails. Default value is `172.19.199.1`, which is the address of the Host OS.

- `SMTP_PORT`: Port used for SMTP. Default is `25`.


### Mailman-Core

These are the variables that you MUST change before deploying:

- `HYPERKITT_API_KEY`: Hyperkitty's API Key, should be set to the same value as
  set for the mailman-core.

- `DATABASE_CLASS`: Default value is `mailman.database.sqlite.SQLiteDatabase`.

These are the variables that you don't need to change if you are using a
standard version of docker-compose.yaml from this repository.

- `MM_HOSTNAME`: Default value is `mailman-core`

- `SMTP_HOST`: IP Address/hostname from which you will be sending
  emails. Default value is `172.19.199.1`, which is the address of the Host OS.

- `SMTP_PORT`: Port used for SMTP. Default is `25`.

- `HYPERKITTY_API_URL`: Default value is `http://mailman-web:8000/hyperkitty`

- `DATABASE_URL`: URL of the type
  `driver://user:password@hostname:port/databasename` for the django to use. If
  not set, the default is set to
  `sqlite:///opt/mailman-web-data/mailmanweb.db`. The standard
  docker-compose.yaml comes with it set to a postgres database. It is not must
  to change this if you are happy with postgresql.


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
