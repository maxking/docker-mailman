#! /usr/bin/env python3
import os
import sys
import gitlab


def usage():
    print("{} <project_name> <project_branch>")


def main():
    if 2 > len(sys.argv) > 3:
        usage()

    project_name = sys.argv[1]
    if len(sys.argv) > 2:
        branch_name = sys.argv[2]
    else:
        branch_name = 'master'

    gl_token = os.getenv('GITLAB_TOKEN')
    if gl_token is None:
        print('GITLAB_TOKEN not set!')
        exit(1)
    gl = gitlab.Gitlab('https://gitlab.com/', gl_token)

    project = gl.projects.get(project_name)
    branch = project.branches.get(branch_name)
    top_commit = project.commits.get(branch.commit['short_id'])

    if top_commit.last_pipeline['status'] == 'success':
        print(top_commit.short_id)
    else:
        exit(1)


if __name__ == '__main__':
    main()
