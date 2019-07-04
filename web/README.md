Mailman 3 Web UI
================

This image consists of Mailman3's Web UI(Postorius) and Archiver
(Hyperkitty). This image is built from latest sources on [gitlab][1]. In future,
latest and stable releases will be seperate. I am looking forward to the release
of Mailman Suite 3.1 before that.

Configuration
=============

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

- `MAILMAN_HOST_IP`: IP of the Container from which Mailman will send emails to
  hyperkitty (django). Set to `172.19.199.2` by default.

- `SMTP_HOST`: IP Address/hostname from which you will be sending
  emails. Default value is `172.19.199.1`, which is the address of the Host OS.

- `SMTP_PORT`: Port used for SMTP. Default is `25`.

- `SMTP_HOST_USER`: Used for SMTP authentication. Default is an empty string.

- `SMTP_HOST_PASSWORD`: Default is an empty string.

- `SMTP_USE_TLS`: Specifies wheather the SMTP connection is encrypted
  via TLS. Default is `False`.

- `DJANGO_LOG_URL`: Path to the django's log file. Defaults to
  `/opt/mailman-web-data/logs/mailmanweb.log`.

- `DJANGO_ALLOWED_HOSTS`: Entry to add to ALLOWED_HOSTS in Django
  configuration. This is a separate configuration from`SERVE_FROM_DOMAIN` as
  latter is used for other purposes too.

- `POSTORIUS_TEMPLATE_BASE_URL`: The base url at which the `mailman-web`
  container can be reached from `mailman-core` container. This is set to
  `http://mailman-web:8000` by default so that Core can fetch templates from
  Web.

Running
=======

It is highly recommended that you run this using the [docker-compose.yaml][2]
provided in the [github repo][3] of this project. You will need to proxy the
requests the container that you create with this image using an actual web
server like Nginx. The [github repo][3] provides the setup instructions for
Nginx.

Since the setup has `USE_SSL` set to `True` in django's `settings.py`, you may
also want to get a SSL certificate if you don't already have one. [Lets
Encrypt][4] provides free SSL certiticates for everyone and there are _some_
instructions about that also.

After the first run, you can create a superuser for django using the following
command:

```bash
    $ docker exec -it mailman-web python manage.py createsuperuser
```

[1]: https://gitlab.com/mailman
[3]: https://github.com/maxking/docker-mailman/
[2]: https://github.com/maxking/docker-mailman/blob/master/docker-compose.yaml
[4]: https://letsencrypt.org
