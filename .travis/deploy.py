#! /usr/bin/env python

import os
import subprocess

#: Default user, which owns the repositories.
USER = 'maxking'


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


if __name__ == '__main__':

    img_tag = 'rolling'

    prev_failed = False

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
