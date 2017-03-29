#!/usr/bin/env python

"""An executable which proxies for a subprocess; upon a signal, it sends that
signal to the process identified by a pidfile.

This is a modified version of the pidproxy.py from supervisor's repository,
which can be found at:

https://github.com/Supervisor/supervisor/blob/master/supervisor/pidproxy.py
"""

import os
import sys
import signal
import time
from subprocess import run


# The sleep time before the watcher checks if the mailman process is still
# living.
SLEEP_TIME = 5


class PidProxy:
    pid = None

    def __init__(self, args):
        self.setsignals()
        try:
            self.pidfile, cmdargs = args[1], args[2:]
            self.pidfile = os.path.abspath(self.pidfile)
            self.args = cmdargs
        except (ValueError, IndexError):
            self.usage()
            sys.exit(1)

    def go(self):
        run(self.args)
        time.sleep(2)
        with open(self.pidfile, 'r') as f:
            self.pid = int(f.read().strip())
        while 1:
            time.sleep(SLEEP_TIME)
            try:
                pid, sts = os.waitpid(-2, os.WNOHANG)
            except OSError:
                pid, sts = None, None
            if pid:
                break

    def usage(self):
        print("pidproxy.py <pidfile name> <command> [<cmdarg1> ...]")

    def setsignals(self):
        signal.signal(signal.SIGTERM, self.passtochild)
        signal.signal(signal.SIGHUP, self.passtochild)
        signal.signal(signal.SIGINT, self.passtochild)
        signal.signal(signal.SIGUSR1, self.passtochild)
        signal.signal(signal.SIGUSR2, self.passtochild)
        signal.signal(signal.SIGQUIT, self.passtochild)
        signal.signal(signal.SIGCHLD, self.reap)

    def reap(self, sig, frame):
        # do nothing, we reap our child synchronously
        pass

    def passtochild(self, sig, frame):
        if self.pid is None:
            sys.exit(1)
        os.kill(self.pid, sig)
        if sig in [signal.SIGTERM, signal.SIGINT, signal.SIGQUIT]:
            sys.exit(0)


def main():
    pp = PidProxy(sys.argv)
    pp.go()

if __name__ == '__main__':
    main()
