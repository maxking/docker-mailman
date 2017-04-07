Mailman3 Core Docker Image
==========================

To run this container, you need a valid configuration at
`/opt/mailman/mailman.cfg` on your host. When you spawn off this container, you
must mount `/opt/mailman` to the container. Mailman's `var` directory will also
be stored here so that it can persist across different sessions and containers.

It is not advised to run multiple mailman processes on the same host sharing the
same `/opt/mailman` directory as this will almost certainly be dangerous.


Configuration
=============

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

[archiver.hyperkitty]
class: mailman_hyperkitty.Archiver
enable: yes
configuration: /config/mailman-hyperkitty.cfg

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

[1]: https://github.com/maxking/docker-mailman.git
