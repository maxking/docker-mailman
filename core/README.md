Mailman3 Core Docker Image
==========================

When you spawn off this container, you must mount `/opt/mailman` to the
container. Mailman's `var` directory will also be stored here so that it can
persist across different sessions and containers. Any configuration at
`/opt/mailman/core/mailman-extra.cfg` (on the host) will be added to the mailman's default
generated confifguration (See below).

It is not advised to run multiple mailman processes on the same host sharing the
same `/opt/mailman` (`/opt/mailman/core` on the host) directory as this will
almost certainly be dangerous.


Configuration
=============

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


These are the variables that you don't need to change if you are using a
standard version of docker-compose.yaml from this repository.

- `MM_HOSTNAME`: Which IP should Core bind to for REST API and LMTP. If not
  defined output for `hostname -i` command is used.

- `MAILMAN_REST_PORT`: Which port should Core use for the REST API. If not defined
  the default is `8001`.

- `MAILMAN_REST_USER`: Which username should Core use for the REST API. If not
  defined the default is `restadmin`.

- `MAILMAN_REST_PASSWORD`: Which password should Core use for the REST API. If
  not defined the default is `restpass`.

- `MTA`: Mail Transfer Agent to use. Either `exim` or `postfix`. Default value is `exim`.

- `SMTP_HOST`: IP Address/hostname from which you will be sending
  emails. Default value is `172.19.199.1`, which is the address of the Host OS.

- `SMTP_PORT`: Port used for SMTP. Default is `25`.

- `HYPERKITTY_URL`: Default value is `http://mailman-web:8000/hyperkitty`

Running Mailman-Core
====================

It is highly recomended that you run this image along with the
docker-compose.yaml file provided at the [github repo][1] of this
image. However, it is possibel to run this image as a standalone container if
you want just a mailman-core.

```bash
$ mkdir -p /opt/mailman/core
$ docker run -it -e "HYPERKITTY_API_KEY=changeme" -h mailman-core -v /opt/mailman/core:/opt/mailman mailman-core
```

However, if you don't provide the environment `DATABASE_URL`, the database _may_
not be persistant. All the configuration options are explained in more detail.

If you need mode advanced configuration for mailman, you can create
`/opt/mailman/mailman.cfg` and it be added to the configuration inside the
container. Note that, anything inside this configuration will override the
settings provided via the environment variables and their default values.

By default, the following settings are generated:

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

[runner.retry]
sleep_time: 10s

[webservice]
hostname: $MM_HOSTNAME
port: $MAILMAN_REST_PORT
admin_user: $MAILMAN_REST_USER
admin_pass: $MAILMAN_REST_PASSWORD

[archiver.hyperkitty]
class: mailman_hyperkitty.Archiver
enable: yes
configuration: /etc/mailman-hyperkitty.cfg

[database]
class: $DATABASE_CLASS
url: $DATABASE_URL
```

```
# mailman-hyperkitty.cfg
[general]
base_url: $HYPERKITTY_URL
api_key: $HYPERKITTY_API_KEY
```

MTA
===

You can use Postfix or [Exim][2] with this image to send emails. Mailman Core
can interact with any modern MTA which can deliver emails over LMTP. The
documentation for Mailman Core has configuration settigs for using them.

Only Exim and Postfix has been tested with these images and are supported as of
now. There _might_ be some limitations with using other MTAs in a containerized
environments. Contributions are welcome for anything additional needed to
support other MTAs.

To setup Exim or Posfix, checkout the [documentation][3].

[1]: https://github.com/maxking/docker-mailman
[2]: http://www.exim.org
[3]: https://asynchronous.in/docker-mailman#setting-up-your-mta
