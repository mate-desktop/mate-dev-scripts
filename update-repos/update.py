#!/usr/bin/env python3

# Author: Steve Zesch

# This script assumes that the repos are locally organized
# as some_parent_folder/mate_repo. For instance, my cloned repos
# are stored as mate-desktop/mate-common, mate-desktop/mate-doc-utils, etc.

# Obviously, you want the cwd when the script runs to be the folder that
# contains all the mate repos. You can achieve this by copying this
# script from mate-dev-scripts/update-repos to the parent directory,
# running the script via it's path (mate-dev-scripts/update-repos/update.py),
# or by creating a symbolic link. I prefer the symbolic link method.
# It doesn't matter, so long as the cwd for this script is the parent
# directory of all the mate repos.

import os
import subprocess

# update all the directories
for d in sorted(os.listdir('.')):
    if os.path.isdir(d):
        os.chdir(d)
        if '.git' in os.listdir('.'):
            result = subprocess.run(["git", "rev-parse", "--abbrev-ref", "HEAD"],
                                    stdout=subprocess.PIPE, text=True)
            if result.returncode == 0:
                if result.stdout.strip() == "master":
                    subprocess.run(["git", "pull", "--quiet"])
                    print(d + ": updated.")
                else:
                    print(d + ": not on master branch, skipping.")
            else:
                print(d + ": error getting current branch name.")
        os.chdir('..')
