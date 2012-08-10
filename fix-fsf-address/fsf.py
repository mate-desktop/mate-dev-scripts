#! /usr/bin/python

# Author: Steve Zesch
# Helper script for fixlicense.sh.

import os
import subprocess
import sys

if len(sys.argv) < 2:
    sys.exit(1)

os.chdir(sys.argv[1])

to_edit = open("filestofix.mate", "w")

output = subprocess.check_output(["licensecheck", "-r", "."])

output = output.split("\n")

foo = []

for f in output:
    foo.append(f.split(" "))

for f in foo:
    temp = f[0].rstrip(":")
    if len(temp) > 0:
        to_edit.write(temp + "\n")

to_edit.close()
