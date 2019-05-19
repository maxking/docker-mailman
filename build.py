#/usr/bin/env python3

# This is the build script to build container images for Mailman.
import sys
import subprocess
from pathlib import Path


STABLE_DOCKERFILES = {
    'core-stable': Path('core/Dockerfile'),
    'web-stable': Path('web/Dockerfile'),
    'postorius-stable': Path('postorius/Dockerfile'),
}

ROLLING_DOCKERFILES = {
    'core-dev': Path('core/Dockerfile.dev'),
    'web-dev': Path('web/Dockerfile.dev'),
    'postorius-dev': Path('postorius/Dockerfile.dev'),
}

VARIANTS = {
    'stable': STABLE_DOCKERFILES,
    'rolling': ROLLING_DOCKERFILES,
}

def run_command(args):
    print(' '.join(args))
    subprocess.run(
        args,
        stdout=sys.stdout,
        stderr=sys.stderr,
        check=True)


def docker_build(dockerfile, tag, args=None, labels=None):
    cmd = [
        'docker', 'build',
        '-t', tag,
        '-f', str(dockerfile),
        str(dockerfile.parent)
    ]

    if args:
        for arg in args:
            cmd.append('--build-arg')
            cmd.append(arg)

    if labels:
        for label in labels:
            cmd.append('--label')
            cmd.append(label)

    return run_command(cmd)


def docker_tag(from_tag, to_tag):
    cmd = [
        'docker', 'tag',
        from_tag, to_tag,
    ]

    return run_command(cmd)

def usage():
    print('usage: python build.py (stable|rolling)')


if __name__ == '__main__':
    if len(sys.argv) < 2:
        usage()
        sys.exit(1)

    variant = sys.argv[1]
    if variant not in VARIANTS:
        usage()
        sys.exit(1)

    for name, path in VARIANTS[variant].items():
        docker_build(dockerfile=path, tag=name)
