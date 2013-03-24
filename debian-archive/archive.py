#!/usr/bin/env python
import optparse
import os
import sys
import subprocess

parser = optparse.OptionParser()
parser.add_option("-v", "--version", dest="version", help="set upstream version")
parser.add_option("-o", "--orig", dest="orig", action="store_true", help="rename file to use with debuild")
parser.add_option("-b", "--branch", dest="branch", help="set the branch to archive")
(options, args) = parser.parse_args()

if len(args) == 0:
    print "E: No package given!"
    sys.exit(1)
elif len(args) > 1:
    print "E: Too many packages given!"
    sys.exit(1)

package = args[0]

if package[-1] == "/":
    print "E: Package name is a directory!"
    sys.exit(1)

if not os.path.exists(package + "/"):
    print "E: Package not found!"
    sys.exit(1)

if options.version is None:
    print "E: Package version not set!"
    sys.exit(1)

# checkout a different branch, if the user chose to do so
if options.branch:
    os.chdir(package)

    # get the current branch
    try:
        output = subprocess.check_output(["git", "branch"]).split("\n")
        
        for line in output:
            if line[0] == "*":
                current_branch = line[2:]
                break

    except subprocess.CalledProcessError:
        print "E: Unable to get a list of branches for this directory."
        sys.exit(1)

    # checkout the desired branch
    try:
        ret_val = subprocess.check_output(["git", "checkout", options.branch], stderr = sys.stdout).rstrip("\n")
        print "I: {}".format(ret_val)
    except subprocess.CalledProcessError:
        print "E: Could not checkout branch {} make sure it exists.".format(options.branch)
        sys.exit(1)

    os.chdir("..")  

# update ChangeLog
os.chdir(package)
os.system("git log --stat > ChangeLog")
print "E: Updated ChangeLog."
os.chdir("..")

version = options.version

print "I:", package, options.version

os.system("cp %(package)s/ %(package)s-%(version)s/ -R" % {"package": package, "version": version})
os.system("rm -rf %(package)s-%(version)s/.git" % {"package": package, "version": version})
os.system("rm -rf %(package)s-%(version)s/.tx" % {"package": package, "version": version})
os.system("rm -rf %(package)s-%(version)s/distro" % {"package": package, "version": version})
os.system("tar cf %(package)s-%(version)s.tar %(package)s-%(version)s/" % {"package": package, "version": version})
#os.system("bzip2 %(package)s-%(version)s.tar" % {"package": package, "version": version})
os.system("xz --compress %(package)s-%(version)s.tar" % {"package": package, "version": version})
os.system("rm -rf %(package)s-%(version)s/" % {"package": package, "version": version})
if options.orig:
    #os.system("mv %(package)s-%(version)s.tar.bz2 %(package)s_%(version)s.orig.tar.bz2" % {"package": package, "version": version})
    os.system("mv %(package)s-%(version)s.tar.xz %(package)s_%(version)s.orig.tar.xz" % {"package": package, "version": version})

os.system("rm %(package)s/ChangeLog" % {"package": package})

# change the branch back to what it was prior to running this script
if options.branch:
    os.chdir(package)

    try:
        ret_val = subprocess.check_output(["git", "checkout", current_branch], stderr = sys.stdout).rstrip("\n")
        print "I: {}".format(ret_val)
    except subprocess.CalledProcessError:
        print "E: Could not checkout the original branch. Current branch is {}".format(options.branch)
        sys.exit(1)
