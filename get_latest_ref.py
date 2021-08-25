#! /usr/bin/env python
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

    # Find the last commit in the branch that passed the CI
    # successfully and return the reference to it.
    for commit in project.commits.list(ref=branch_name):
        stasues = (status.status == 'success' for status in
                commit.statuses.list() if status.allow_failure == False)
        if len(stasues) == 0:
            continue
        if all(stasues):
            print(commit.short_id)
            break

if __name__ == '__main__':
    main()
