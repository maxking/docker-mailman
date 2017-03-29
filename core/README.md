Mailman3 Core Docker Image
==========================

To run this container, you need a valid configuration at
`/opt/mailman/mailman.cfg` on your host. When you spawn off this container, you
must mount `/opt/mailman` to the container. Mailman's `var` directory will also
be stored here so that it can persist across different sessions and containers.

It is not advised to run multiple mailman processes on the same host sharing the
same `/opt/mailman` directory as this will almost certainly be dangerous.
