#! /usr/bin/env python

# Author: Abhilash Raj
# 
# This is the primary deployment script for the docker-mailman repo. It does
# deployment for stable and rolling releases both. It should be *always* invoked
# and it will make the deployment decision based on the environment variables
# that it sees.
#
# There are two kinds of deploymnets primarily:
# 1. Rolling tags, which are built from each commit. These are typically run 
#    in CI every day as well. These always update the "rolling" tag in the
#    docker registry.
# 2. Stable tags, which are built from git tags with "va.b.c" tags. We don't
#    do the tag verification because for now, Circle CI does this for us. We
#    will tag and release a stable version whenever the right ENV var is set.
#
# Publishing:
# We are typically publishing all the images to three repositories:
# 1. Docker Hub: This is now rate-limited and might cause issues for people
#    pulling too frequently.
# 2. Quay: This is an old registry that we started publishing too, so let's
#    continue publishing here too.
# 3. Github Registry: This is the newest one in the mix and supports free
#    uploads and downloads (without very strict rate limits like Dockerhub.)

import os
import subprocess

#: Default user, which owns the repositories.
USER = 'maxking'

TAG_VAR = 'CIRCLE_TAG'
BRANCH_VAR = 'CIRCLE_BRANCH'
PRIMARY_BRANCH = 'master'


def tag(original, final):
    """Tag the source image with final tag."""
    try:
        print('Tagging {0} to {1}'.format(original, final))
        subprocess.run(
            ['docker', 'tag', original, final],
            check=True,
        )
    except subprocess.CalledProcessError:
        print('Failed to tag {0}'.format(original))


def login(url):
    """Login to the registry."""
    if 'quay' in url.lower():
        password = os.environ['QUAY_PASSWORD']
    elif 'docker' in url.lower():
        password = os.environ['DOCKER_PASSWORD']
    elif 'ghcr' in url.lower():
        password = os.environ['GITHUB_PASSWORD']
    else:
        print('Password not found for {0}'.format(url))
        return None
    print('Logging in to {0}'.format(url))
    subprocess.run(
        ['docker', 'login', '-u', USER, '-p', password, url],
        check=True
    )
    print('Logged in to {0}'.format(url))


def push(image):
    """Push all the images."""
    print('Pushing {}'.format(image))
    subprocess.run(['docker', 'push', image], check=True)


def tag_and_push(image_names, url, img_tag):
    """Given the URL to repository, tag and push the images."""
    # Tag recently built images.
    source, final = image_names
    tag(source, final)
    # Finall, push all the images.
    push(final)


def main():
    """Primary entrypoint to this script."""
    
    if os.environ.get(TAG_VAR) not in (None, ''):
        img_tag = os.environ.get(TAG_VAR)
    elif os.environ.get(BRANCH_VAR) == PRIMARY_BRANCH:
        img_tag = 'rolling'
    else:
        print(f'Not running on master branch or Git tag so not publishing...')
        exit(0)

    for url in ('quay.io', 'docker.io', 'ghcr.io'):

        core = ('maxking/mailman-core:rolling',
                '{0}/maxking/mailman-core:{1}'.format(url, img_tag))
        web = ('maxking/mailman-web:rolling',
               '{0}/maxking/mailman-web:{1}'.format(url, img_tag))
        postorius = ('maxking/postorius:rolling',
                     '{0}/maxking/postorius:{1}'.format(url, img_tag))

        try:
            login(url)
        except subprocess.CalledProcessError:
            print('Failed to login to {}'.format(url))
            continue

        tag_and_push(core, url, img_tag)
        tag_and_push(web, url, img_tag)
        tag_and_push(postorius, url, img_tag)


if __name__ == '__main__':

    main()


