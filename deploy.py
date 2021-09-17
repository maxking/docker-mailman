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
from packaging import version

#: Default user, which owns the repositories.
USER = 'maxking'

TAG_VAR = 'CIRCLE_TAG'
BRANCH_VAR = 'CIRCLE_BRANCH'
PRIMARY_BRANCH = 'main'


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


def get_tag_without_patch(tag):
    """Given A.B.C return A.B"""
    v = version.parse(tag)
    return '{}.{}'.format(v.major, v.minor)


def get_urls(url, img_tag):
    core = ('maxking/mailman-core:rolling',
            '{0}/maxking/mailman-core:{1}'.format(url, img_tag))
    web = ('maxking/mailman-web:rolling',
        '{0}/maxking/mailman-web:{1}'.format(url, img_tag))
    postorius = ('maxking/postorius:rolling',
        '{0}/maxking/postorius:{1}'.format(url, img_tag))

    return (core, web, postorius)
                     


def main():
    """Primary entrypoint to this script."""
    # Boolean signifying if this is a stable release tag or just a branch.
    is_release = False

    if os.environ.get(TAG_VAR) not in (None, ''):
        img_tag = os.environ.get(TAG_VAR)
        # Released versions are tagged vA.B.C, so remove
        # v from the tag when creating the release.
        if img_tag.startswith('v'):
            img_tag = img_tag[1:]
            is_release = True

    elif os.environ.get(BRANCH_VAR) == PRIMARY_BRANCH:
        img_tag = 'rolling'
    else:
        print('Not running on {PRIMARY_BRANCH} branch or Git tag so not publishing...'.format(
            PRIMARY_BRANCH=PRIMARY_BRANCH))
        exit(0)

    # All the registries we are pushing to.
    for url in ('quay.io', 'docker.io', 'ghcr.io'):

        try:
            login(url)
        except subprocess.CalledProcessError:
            print('Failed to login to {}'.format(url))
            continue
        
        # Push all the container images.
        for each in get_urls(url, img_tag):
            tag_and_push(each, url, img_tag)

        # If this is a release tag, tag them also with a.b version.
        if is_release:
            rel_tag = get_tag_without_patch(img_tag)
            for each in get_urls(url, rel_tag):
                tag_and_push(each, url, rel_tag)



if __name__ == '__main__':

    main()


