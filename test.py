#!/usr/bin/env python3

import sys
from pathlib import Path
from build import VARIANTS

DOCKER_TEST="""version: '2'

services:
mailman-core:
image: maxking/mailman-core:{variant}

mailman-web:
image: maxking/mailman-web:{variant}
environment:
- SECRET_KEY=abcdefghijklmnopqrstuv
"""


def test_setup(variant):
    Path('docker-test.yaml').write_text(
        DOCKER_TEST.format(variant=variant))


def usage():
    print('usage: python test.py (stable|rolling)')


if __name__ == '__main__':
    if len(sys.argv) < 2:
        usage()
        sys.exit(1)

    variant = sys.argv[1]
    if variant not in VARIANTS:
        usage()
        sys.exit(1)

    test_setup(variant)
