# NEWS

## Outdated

Please see [release page](https://github.com/maxking/docker-mailman/releases)
for the latest releases and change log.


## Mailman Core

### v1.1.1 (released Aug 9 2017)

- The MAILMAN_HOST now defaults to output of `hostname -i` instead of `mailman-core`. This
  is the hostname Core binds to for Webservice.
- Added pymysql to the image to use MySQL as database.
- The default settings for using SQLITE are now more sane.
- Postfix's transport maps are generated at the container startup now even when
  there is no lists exist.


## Mailman Web

### v1.1.1 (released Aug 9 2017)

- The default search_index for whoosh now exists on persistent storage at
  `/opt/mailman-web-data`
- Move to using Alpine instead of Debian for this image, python2.7:alpine-3.6
  image is now the base image
- Django compressor is now using `sassc` from alpine repo.
- Default value of SECRET_KEY is now removed. It is MUST to set SECRET_KEY
  environment variable to run this image now.
- If a SERVE_FROM_DOMAIN environment variable is defined, the default Django's
  example.com site is renamed to this domain. The SITE_ID remains same so there
  is no change required to serve this domain.
- If MAILMAN_ADMIN_USER and MAILMAN_ADMIN_EMAIL environment variables are
  defined a Django Superuser is created by default. The password for this user
  would have to be reset on the first login.
- Fix cron configuration which would run them in wrong order.
- Removed facebook as default social auth provider in the settings.py
- Uwsgi now listens on port 8080 for uwsgi protocol and 8000 for http protocol.
- Threads are enabled by default in the uwsgi configuration now.
- Hyperkitty updated to v1.1.1
