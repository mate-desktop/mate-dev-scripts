#! /usr/bin/python

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

# update all the directories
for d in os.listdir('.'):
    if os.path.isdir(d):
        os.chdir(d)
        if '.git' in os.listdir('.'):
            os.system('git pull')
        os.chdir('..')
